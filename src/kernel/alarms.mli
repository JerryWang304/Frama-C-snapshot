(**************************************************************************)
(*                                                                        *)
(*  This file is part of Frama-C.                                         *)
(*                                                                        *)
(*  Copyright (C) 2007-2010                                               *)
(*    CEA (Commissariat � l'�nergie atomique et aux �nergies              *)
(*         alternatives)                                                  *)
(*                                                                        *)
(*  you can redistribute it and/or modify it under the terms of the GNU   *)
(*  Lesser General Public License as published by the Free Software       *)
(*  Foundation, version 2.1.                                              *)
(*                                                                        *)
(*  It is distributed in the hope that it will be useful,                 *)
(*  but WITHOUT ANY WARRANTY; without even the implied warranty of        *)
(*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *)
(*  GNU Lesser General Public License for more details.                   *)
(*                                                                        *)
(*  See the GNU Lesser General Public License version 2.1                 *)
(*  for more details (enclosed in the file licenses/LGPLv2.1).            *)
(*                                                                        *)
(**************************************************************************)

(** Alarm Database.
    @plugin development guide *)

type t =
  | Division_alarm
  | Memory_alarm
  | Index_alarm
  | Shift_alarm
  | Pointer_compare_alarm
  | Signed_overflow_alarm
  | Using_nan_or_infinite_alarm
  | Result_is_nan_or_infinite_alarm
  | Separation_alarm
  | Other_alarm

val pretty : Format.formatter -> t -> unit
val register: Cil_types.kinstr -> t -> Cil_types.code_annotation -> bool
val clear: unit -> unit

val iter: (Cil_types.kinstr -> (t * Cil_types.code_annotation) -> unit) -> unit

val fold: 
  (Cil_types.kinstr -> (t * Cil_types.code_annotation) -> 'a -> 'a) -> 'a -> 'a

val fold_kinstr: 
  Cil_types.kinstr -> ((t*Cil_types.code_annotation) -> 'a -> 'a) -> 'a -> 'a

val self: Project.Computation.t

(*
Local Variables:
compile-command: "LC_ALL=C make -C ../.."
End:
*)