(*---------------------------------------------------------------------------
   Copyright (c) 2018 The b0 programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

open B0_std
open B0_std.Fut.Syntax
open Test_memo_setup

let lookup_b0_os build_dir m =
  let store = B0_store.create m ~dir:build_dir [] in
  let* n = B0_store.get store B0_os.name in
  let* v = B0_store.get store B0_os.version in
  let* d = B0_store.get store B0_os.distribution in
  let* f = B0_store.get store B0_os.family in
  let* a = B0_store.get store B0_os.arch in
  let* an = B0_store.get store B0_os.arch_normalized in
  let* bits = B0_store.get store B0_os.arch_bits in
  Log.app (fun m ->
      m "@[<v>%a@,%a@,%a@,%a@,%a@,%a@,%a@]"
        Fmt.(field "name" id string) n
        Fmt.(field "version" id string) v
        Fmt.(field "distribution" id string) d
        Fmt.(field "family" id string) f
        Fmt.(field "arch" id string) a
        Fmt.(field "arch-normalized" id string) an
        Fmt.(field "arch-bits" id int) bits);
  Fut.return ()

let test_memo_store () =
  with_memo lookup_b0_os;
  ()

let () = test_memo_store ()
