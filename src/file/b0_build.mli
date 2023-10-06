(*---------------------------------------------------------------------------
   Copyright (c) 2020 The b0 programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(** B0 builds.

    Centralizes the information to run and orchestrate a B0 build. *)

open B0_std

(** {1:builds Build} *)

type t = B0_unit.build
(** The type for builds. *)

val memo : t -> B0_memo.t
(** [memo b] the memoizer for the build. *)

(** {1:units Units} *)

val must_build : t -> B0_unit.Set.t
(** [must_build b] are the units in [b] that must build. *)

val may_build : t -> B0_unit.Set.t
(** [may_build b] are all the units in [b] that may build, i.e. that
    can be {!require}d. This includes the elements in [must_build b]. *)

val require : t -> B0_unit.t -> unit
(** [require b u] asks to build unit [u] in [b]. This fails the
    memo if [b] is [u] is not in {!may_build}. *)

val current : t -> B0_unit.t
(** [current b] is [b]'s current unit. In the {{!B0_unit.type-proc}procedure}
    of a build unit this is the unit itself. *)

val current_meta : t -> B0_meta.t
(** [current_meta b] is [B0_unit.meta (current b)]. *)

(** {1:dir Directories}

    {b FIXME} Unify the directory story with {!B0_action} and
    We likely want to get rid of a few of the functions below. *)

val scope_dir : t -> B0_unit.t -> Fpath.t
(** [scope_dir b u] is the directory of the B0 file in which [u] was
    defined. This is were unit relative paths like source files
    should be resolved. *)

val build_dir : t -> B0_unit.t -> Fpath.t
(** [build_dir b u] is the build directory for the build unit [u].
    This is where [u] should write is build artefacts. *)

val shared_build_dir : t -> Fpath.t
(** [shared_build_dir] is a build directory shared by all units of the
     build. This is used by computations shared by units, most of the
     time one should rather use {!current_build_dir}. *)

val current_scope_dir : t -> Fpath.t
(** [current_scope_dir b] is [root_dir b current]. *)

val current_build_dir : t -> Fpath.t
(** [current_unit_build_dir b] is [build_dir b current]. *)

val in_build_dir : t -> Fpath.t -> Fpath.t
(** [in_build_dir b p] is [Fpath.(build_dir b current // p)]). *)

val in_scope_dir : t -> Fpath.t -> Fpath.t
(** [in_scope_dir b p] is [Fpath.(scope_dir b current // p)]). *)

val in_shared_build_dir : t -> Fpath.t -> Fpath.t
(** [in_shared_build_dir b p] is [Fpath.(shared_build_dir b // p)]). *)

(** {1:store Store} *)

val store : t -> B0_store.t
(** [store b] is the store for the build. Note that [b] itself
    can be found in store via the {!self} key. *)

val get : t -> 'a B0_store.key -> 'a Fut.t
(** [get b k] is {!B0_store.get}[ (store b) k]. *)

val self : t B0_store.key
(** [self] is a store key that holds the build itself. The store
    returned by {!val-store} has this key bound to the build. *)

(** {1:run Creating and running} *)

val make :
  root_dir:Fpath.t -> b0_dir:Fpath.t -> variant:string ->
  store:B0_store.binding list -> B0_memo.t ->
  may_build:B0_unit.Set.t -> must_build:B0_unit.Set.t -> t
(** [make ~root_dir ~b0_dir m ~may_build ~must_build]
    {ul
    {- [must_build] are the build units that must be build by [b].}
    {- [may_build] are the build units that may build in [b]. [must] units
        are automatically added to this set.}} *)

val run : t -> (unit, unit) result
(** [run b] runs the build. *)

val did_build : t -> B0_unit.Set.t
(** [did_build b] are the units that did build. This is meaningless before
    {!val-run} has finished. *)
