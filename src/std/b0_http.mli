(*---------------------------------------------------------------------------
   Copyright (c) 2016 The b0 programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(** HTTP client.

    Good enough (?) toys to interact with the World Wide Web.  *)

open B0_std

(** HTTP datatypes. *)
module Http : sig

  type method' =
  [ `CONNECT | `DELETE | `GET | `HEAD | `OPTIONS | `Other of string
  | `PATCH | `POST | `PUT | `TRACE ]
  (** The type for HTTP methods. *)

  val method_to_string : method' -> string
  (** [method_to_string m] is an HTTP method string for [m]. *)

  type headers = (string * string) list
  (** The type for HTTP headers. List of header names (without the [:])
      tupled with their value. *)

  (** HTTP requests. *)
  module Request : sig

    type t
    (** The type for HTTP requests. *)

    val make : ?headers:headers -> ?body:string -> url:Url.t -> method' -> t
    (** [make uri m ~headers ~body] is a request on [url] with method [m],
        headers [headers] (defaults to [[]]) and body [body] (defaults to
        [""]). *)

    val url : t -> Url.t
    (** [url r] is the URL of [r]. *)

    val method' : t -> method'
    (** [meth r] is the method of [r]. *)

    val headers : t -> headers
    (** [headers r] are the headers of [r]. *)

    val body : t -> string
    (** [body r] is the body of [r]. *)
  end

  (** HTTP responses. *)
  module Response : sig

    type t
    (** The type for HTTP responses. *)

    val make : ?headers:headers -> ?body:string -> int -> t
    (** [make status ~headers ~body] is a response with status [status],
        headers [headers] (defaults to [[]]) and body [body]
        (defaults to [""]). *)

    val of_string : string -> (t, string) result
    (** [of_string s] is a response from [s]. *)

    val status : t -> int
    (** [status r] is the status of [r]. *)

    val headers : t -> headers
    (** [headers r] are headers of [r] *)

    val body : t -> string
    (** [body r] is body of [r]. *)
  end
end

(** HTTP clients. *)
module Http_client : sig

  type t
  (** The type for HTTP clients. *)

  val get : ?search:Cmd.tool_search -> ?cmd:Cmd.t -> unit -> (t, string) result
  (** [get ~search ~cmd ()] looks for [cmd] (defaults to [Cmd.tool "curl"])
      in [search] (defaults to [Os.Cmd.get ~search]). *)

  val fetch :
    ?insecure:bool -> ?follow:bool -> t -> Http.Request.t ->
    (Http.Response.t, string) result
  (** [fetch httpr r] performs request [r] via [httpr].  If [follow]
      is [true] (default) HTTP redirects for GET and HEAD requests
      that return 301, 302, 303, 305 or 307 are automatically
      followed. If [insecure] is [true] (defaults to [false]) TLS
      server certificates are not checked.

      The response's {!Http.Response.headers} are lowercased. *)

  (** {1:cli Command line interface} *)

  val curl :
    ?docs:string -> ?env:Cmdliner.Cmd.Env.info -> unit -> Cmd.t Cmdliner.Term.t
  (** [curl] is a cli interface for specifying the curl command
      line tool. *)
end
