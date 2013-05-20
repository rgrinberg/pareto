(** Commonly used sample statistics. *)

open Internal

val min    : float array -> float
val max    : float array -> float
val minmax : float array -> (float * float)

(** {e O(n)} Computes sample's range, i. e. the difference between the
    largest and smallest elements of a sample. *)
val range : float array -> float

(** {e O(n)} Computes sample's arithmetic mean. *)
val mean : float array -> float

(** {e O(n)} Computes unbiased estimate of a sample's variance, also
    known as the {e sample variance}, where the denominator is [n - 1]. *)
val variance : ?mean:float -> float array -> float

(** {e O(n)} Computes sample's standard deviation. *)
val sd : ?mean:float -> float array -> float

(** {e O(n log n)} Computes sample's ranks, [ties_strategy] controls
    which ranks are assigned to equal values:

    - [`Average] the average of ranks should be assigned to each value.
      {b Default}.
    - [`Min] the minimum of ranks is assigned to each value.
    - [`Max] the maximum of ranks is assigned to each value.

    Returns a pair, where the first element is ties correction factor
    and second is an array of sample ranks.

    {6 References}

    + P. R. Freeman, "Algorithm AS 26: Ranking an array of numbers",
      Vol. 19, Applied Statistics, pp111-113, 1970. *)
val rank
  :  ?ties_strategy:[`Average | `Min | `Max]
  -> ?cmp:('a -> 'a -> int)
  -> 'a array
  -> (float * float array)

(** {e O(n)} Computes histogram of a data set. Bin sizes are uniform,
    based on a given [range], whic defaults to
    [(min - k, max + k)], where [k = (min - max) / (bins - 1) * 2].
    This behaviour is copied from the excellent
    {{: http://github.com/bos/statistics} statistics} library by
    Brian O'Sullivan. *)
val histogram
  :  ?bins:int
  -> ?range:(float * float)
  -> ?weights:float array
  -> ?density:bool
  -> float array
  -> (float array * float array)


module Quantile : sig
  (** Parameters for the continious sample method. *)
  type continous_param =
    | CADPW           (** Linear interpolation of the {e ECDF}. *)
    | Hazen           (** Hazen's definition. *)
    | SPSS            (** Definition used by the SPSS statistics application,
                          also known as Weibull's definition. *)
    | S               (** Definition used by the S statistics application.org
                          Interpolation points divide the sample range into
                          [n - 1] intervals. {b Default}. *)
    | MedianUnbiased  (** Median unbiased definition. The resulting quantile
                          estimates are approximately median unbiased
                          regardless of the distribution of [vs] *)
    | NormalUnbiased  (** Normal unbiased definition. An approximately unbiased
                          estimate if the empirical distribution approximates
                          the normal distribution. *)

  (** {e O(n log n)} Estimates sample quantile corresponding to the given
      probability [p], using the continuous sample method with given
      parameters. *)
  val continous_by
    : ?param:continous_param -> ?p:float -> float array -> float

  (** {e O(n log n)} Estimates interquantile range of a given sample,
      using the continuous sample method with given parameters. *)
  val iqr : ?param:continous_param -> float array -> float
end

(** {e O(n log n)} Estimates sample quantile corresponding to the given
    probability [p], using the continuous sample method with default
    parameters. *)
val quantile : ?p:float -> float array -> float

(** {e O(n log n)} Estimates interquantile range of a given sample,
    using the continuous sample method with given parameters. *)
val iqr : float array -> float


open Internal

(** {e O(n)} Shuffles a given array using Fisher-Yates shuffle. *)
val shuffle : ?rng:Rng.t -> 'a array -> 'a array

(** {e O(n)} Takes a sample of the specified [size] from the given
    array either with or without replacement. [size] defaults to the
    whole array. *)
val sample
  : ?rng:Rng.t -> ?replace:bool -> ?size:int -> 'a array -> 'a array


module KDE : sig
  (** Bandwith selection rules. *)
  type bandwidth =
    | Silverman  (** Use {e rule-of-thumb} for choosing the bandwidth.
                     It defaults to
                     [0.9 * min(SD, IQR / 1.34) * n^-0.2]. *)
    | Scott      (** Same as [Silverman], but with a factor, equal to
                     [1.06]. *)

  type kernel =
    | Gaussian

  (** {e O(n * points)} Simple kernel density estimator. Returns an array
      of uniformly spaced points from the sample range at which the
      density function was estimated, and the estimates at these points. *)
  val estimate_pdf
    :  ?kernel:kernel
    -> ?bandwidth:bandwidth
    -> ?points:int
    -> float array
    -> (float array * float array)

  (** {6 Example}

      {[
        open Pareto
        let open Distributions.Normal in
        let vs = sample ~size:100 standard in
        let (points, pdf) = Sample.KDE.estimate_pdf ~points:10 vs in begin
          (* Output an ASCII density plot. *)
          Array.iteri (fun i d ->
              let count = int_of_float (d *. 20.) in
              printf "%9.5f " points.(i);
              for i = 0 to count do
                print_char (if i = count then '.' else ' ');
              done;

              print_newline ();
            ) pdf
        end
      ]}

      {6 References}

      + B.W. Silverman, "Density Estimation for Statistics and Data
        Analysis", Vol. 26, Monographs on Statistics and Applied
        Probability, Chapman and Hall, London, 1986. *)
end