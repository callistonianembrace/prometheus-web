(* This code is borrowed from https://github.com/mirage/prometheus
 * which is distributed under the Apache License 2.0
 *)

open Prometheus
open Prometheus_app_pure

module Unix_runtime = struct
  let start_time = Unix.gettimeofday ()

  let simple_metric ~metric_type ~help name fn =
    let info =
      {
        MetricInfo.name = MetricName.v name;
        help;
        metric_type;
        label_names = [];
      } in
    let collect () = LabelSetMap.singleton [] [Sample_set.sample (fn ())] in
    (info, collect)

  let process_start_time_seconds =
    simple_metric ~metric_type:Counter "process_start_time_seconds"
      (fun () -> start_time)
      ~help:"Start time of the process since unix epoch in seconds."

  let metrics = [process_start_time_seconds]
end

let () =
  let add (info, collector) =
    CollectorRegistry.(register default) info collector in
  List.iter add Unix_runtime.metrics

type config = int option

let listen_prometheus =
  let open! Cmdliner in
  let doc =
    Arg.info ~docs:"MONITORING OPTIONS" ~docv:"PORT"
      ~doc:"Port on which to provide Prometheus metrics over HTTP."
      ["listen-prometheus"] in
  Arg.(value @@ opt (some int) None doc)

let opts : config Cmdliner.Term.t = listen_prometheus

let request_handler _ =
  let data = Prometheus.CollectorRegistry.(collect default) in
  let body =
    Fmt.to_to_string TextFormat_0_0_4.output data |> Piaf.Body.of_string in
  let headers =
    Piaf.Headers.of_list [("Content-Type", "text/plain; version=0.0.4")] in
  Piaf.Response.create ~headers ~body `OK |> Lwt.return

let serve : config -> unit Lwt.t = function
  | None -> Lwt.return ()
  | Some port ->
    let open Lwt.Infix in
    let listen_address = Unix.(ADDR_INET (inet_addr_loopback, port)) in
    Lwt.async (fun () ->
        Lwt_io.establish_server_with_client_socket listen_address
          (Piaf.Server.create ?config:None request_handler)
        >|= fun _server ->
        Printf.printf "Listening on port %i and echoing POST requests.\n%!" port);
    let forever, _ = Lwt.wait () in
    forever
