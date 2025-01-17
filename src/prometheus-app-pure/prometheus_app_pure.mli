(* This code is borrowed from https://github.com/mirage/prometheus
 * which is distributed under the Apache License 2.0
 *)

(** Report metrics for Prometheus.
    See: https://prometheus.io/

    Notes:

    - This module is intended to be used by applications that export Prometheus metrics.
      Libraries should only link against the `Prometheus` module.

    - This module automatically initialises itself and registers some standard collectors relating to
      GC statistics, as recommended by Prometheus.

    - This module does not depend on [Unix], and so can be used in unikernels.
 *)

(** Format a snapshot in Prometheus's text format, version 0.0.4. *)
module TextFormat_0_0_4 : sig
  val output : Prometheus.CollectorRegistry.snapshot Fmt.t
end
