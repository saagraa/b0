(*---------------------------------------------------------------------------
   Copyright (c) 2020 The b0 programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

open B0_std
open Result.Syntax

let build_dir us c =
  Log.if_error ~use:B0_cli.Exit.no_such_name @@
  let* us = B0_unit.get_list_or_hint ~empty_means_all:true us in
  let b0_dir = B0_driver.Conf.b0_dir c in
  let build_dir = B0_dir.build_dir ~b0_dir ~variant:"user" (* FIXME *) in
  let unit_dir u = B0_dir.unit_build_dir ~build_dir ~name:(B0_unit.name u) in
  let dirs = List.map unit_dir us in
  Log.app (fun m -> m "@[<v>%a@]" (Fmt.list Fpath.pp) dirs);
  Ok B0_cli.Exit.ok

let edit us c = B0_tool_std.Def.edit (module B0_unit) c us
let get format k us c =
  B0_tool_std.Def.get_meta_key (module B0_unit) c format k us

let list format us c =
  B0_tool_std.Def.list (module B0_unit) c format us

let show format us c =
  let format = if format = `Normal then `Long else format in
  B0_tool_std.Def.list (module B0_unit) c format us

(* Command line interface *)

open Cmdliner

let units ~right:r =
  let doc = "The $(docv) to act on. All of them if unspecified." in
  Arg.(value & pos_right r string [] & info [] ~doc ~docv:"UNIT")

let units_all = units ~right:(-1)

let list_term = Term.(const list $ B0_tool_std.Cli.format $ units_all)

(* Commands *)

let build_dir =
  let doc = "Output build directories of units" in
  let descr = `P "$(iname) outputs build directories of given build units. \
                  The paths may not exist."
  in
  B0_tool_std.Cli.subcmd_with_b0_file "build-dir" ~doc ~descr @@
  Term.(const build_dir $ units_all)

let edit =
  let doc = "Edit build units" in
  let descr = `P "$(iname) opens in your editor the B0 files in which given \
                  build units are defined." in
  let envs = B0_tool_std.Cli.editor_envs in
  B0_tool_std.Cli.subcmd_with_b0_file "edit" ~doc ~descr ~envs @@
  Term.(const edit $ units_all)

let get =
  let doc = "Get build unit metadata" in
  let descr = `P "$(iname) outputs the value of metadata $(i,KEY) of given \
                  build units."
  in
  let envs = B0_tool_std.Cli.pager_envs in
  let units = units ~right:0 in
  B0_tool_std.Cli.subcmd_with_b0_file "get" ~doc ~descr ~envs @@
  Term.(const get $ B0_tool_std.Cli.format $ B0_tool_std.Cli.pos_key $ units)

let list =
  let doc = "List build units (default command)" in
  let descr = `P "$(iname) lists given build units." in
  let envs = B0_tool_std.Cli.pager_envs in
  B0_tool_std.Cli.subcmd_with_b0_file "list" ~doc ~descr ~envs list_term

let show =
  let doc = "Show build unit metadata." in
  let descr = `P "$(iname) is $(b,list -l), it outputs metadata of \
                  given build units."
  in
  let envs = B0_tool_std.Cli.pager_envs in
  let term = Term.(const show $ B0_tool_std.Cli.format $ units_all) in
  B0_tool_std.Cli.subcmd_with_b0_file "show" ~doc ~descr ~envs term

let subs = [build_dir; edit; get; list; show]

let cmd =
  let doc = "Operate on build units" in
  let descr = `P "$(iname) operates on build units. The default command \
                  is $(iname) $(b,list)."
  in
  let envs = B0_tool_std.Cli.pager_envs in
  B0_tool_std.Cli.cmd_group_with_b0_file "unit" ~doc ~descr ~envs subs
