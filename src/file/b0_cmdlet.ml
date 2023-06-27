(*---------------------------------------------------------------------------
   Copyright (c) 2020 The b0 programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

open B0_std

type t = { def : B0_def.t; cmd : cmd }
and cmd = env -> Cmd.t -> Os.Exit.t
and env =
  { cwd : Fpath.t;
    scope_dir : Fpath.t;
    root_dir : Fpath.t;
    b0_dir : Fpath.t;
    cmdlet : t }

module T = struct
  type nonrec t = t
  let def_kind = "cmdlet"
  let def p = p.def
  let pp_name_str = Fmt.(code string)
end

include (B0_def.Make (T) : B0_def.S with type t := t)

let v ?doc ?meta n cmd =
  let def = define ?doc ?meta n in
  let p = { def; cmd } in add p; p

let cmd c = c.cmd

module Env = struct
  type cmdlet = t
  type t = env
  let v ~cwd ~scope_dir ~root_dir ~b0_dir ~cmdlet =
    { cwd; scope_dir; root_dir; b0_dir; cmdlet }

  let cwd e = e.cwd
  let scope_dir e = e.scope_dir
  let root_dir e = e.root_dir
  let b0_dir e = e.b0_dir
  let scratch_dir e = B0_dir.scratch_dir ~b0_dir:e.b0_dir
  let cmdlet e = e.cmdlet
end

(* Shortcuts *)

let exit_some_error e =
  Log.err (fun m -> m "@[%a@]" Fmt.lines e); B0_cli.Exit.some_error

let exit_of_result = function
| Ok _ -> B0_cli.Exit.ok | Error e -> exit_some_error e

let exit_of_result' = function Ok e -> e | Error e -> exit_some_error e

let in_scope_dir env p = Fpath.(Env.scope_dir env // p)
let in_root_dir env p = Fpath.(Env.root_dir env // p)
let in_scratch_dir env p = Fpath.(Env.scratch_dir env // p)

(* Script and tool execution *)

let exec_file ?env:e ?cwd exe env args =
  let scope_dir = Env.scope_dir env in
  let exe = Fpath.(scope_dir // exe) in
  let cwd = Option.value ~default:scope_dir cwd in
  Os.Exit.exec ?env:e ~cwd exe Cmd.(path exe %% args)

let exec_tool ?env:e ?cwd tool env args =
  let scope_dir = Env.scope_dir env in
  match Os.Cmd.get_tool tool with
  | Error e -> exit_some_error e
  | Ok exe ->
      let cwd = Option.value ~default:scope_dir cwd in
      Os.Exit.exec ?env:e ~cwd exe Cmd.(path exe %% args)

(* N.B. that signature could be twisted around to teturn a `cmd` value
   but the way it is now encourages the term definition to occur behind
   a thunk rather at toplevel init. *)

let eval ?man_xrefs ?man ?envs ?exits ?sdocs ?docs ?doc:d ?version e cmd t =
  let cmdlet = Env.cmdlet e in
  let name = name cmdlet in
  let doc = Option.value ~default:(doc cmdlet) d in
  let exits = Option.value ~default:B0_cli.Exit.infos exits in
  let info = Cmdliner.Cmd.info
      ?man_xrefs ?man ?envs ~exits ?sdocs ?docs ?version name ~doc
  in
  let argv = Array.of_list (name :: Cmd.to_list cmd) in
  let cmd = Cmdliner.Cmd.v info t in
  B0_cli.Exit.of_eval_result @@ Cmdliner.Cmd.eval_value ~argv cmd
