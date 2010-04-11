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

(* $Id: ast_info.mli,v 1.29 2009-02-23 12:52:19 uid562 Exp $ *)

(** AST manipulation utilities.
    @plugin development guide *)

open Cil_types
open Db_types

val pretty_vname: Format.formatter -> Cil_types.varinfo -> unit

(* ************************************************************************** *)
(** {2 Annotations} *)
(* ************************************************************************** *)

val before_after_content: 'a before_after -> 'a

val lift_annot_func:
  (code_annotation -> 'a) -> rooted_code_annotation before_after -> 'a
  (** lifts a function that operates on code_annotation up to the
      annotations used in Db. *)

val lift_annot_list_func:
  (code_annotation list -> 'a) ->
  rooted_code_annotation before_after list -> 'a
  (** lifts a function taking lists of code_annotation up to the annotations
      lists in Db. Ignores WP annotations. *)

module Datatype_Annotation:
  Project.Datatype.S with type t = rooted_code_annotation before_after

(* ************************************************************************** *)
(** {2 Expressions} *)
(* ************************************************************************** *)

val is_integral_const: constant -> bool
val possible_value_of_integral_const: constant -> int64 option
val possible_value_of_integral_expr: exp -> int64 option
val value_of_integral_const: constant -> int64
val value_of_integral_expr: exp -> int64
val constant_expr: int64 -> exp
val is_null_expr: exp -> bool
val is_non_null_expr: exp -> bool

(* ************************************************************************** *)
(** {2 Logical terms} *)
(* ************************************************************************** *)

val possible_value_of_integral_term: term -> int64 option

val term_lvals_of_term: term -> term_lval list
  (** Return the list of all the term lvals of a given term.
      Purely syntactic function. *)

val is_trivial_predicate: predicate -> bool
val is_trivial_rooted_assertion: Db_types.rooted_code_annotation -> bool
val is_trivial_named_predicate: predicate named -> bool

val behavior_postcondition : funbehavior -> termination_kind -> predicate named
  (** @modify Boron-20100401 added termination kind as argument *)

val merge_assigns: funbehavior list -> identified_term assigns list

val variable_term: location -> logic_var -> term
val constant_term: location -> int64 -> term
val is_null_term: term -> bool

(* ************************************************************************** *)
(** {2 Predicates} *)
(* ************************************************************************** *)

val predicate: location -> predicate -> predicate named

(* ************************************************************************** *)
(** {2 Statements} *)
(* ************************************************************************** *)

val is_loop_statement: stmt -> bool
val get_sid: kinstr -> int

val loc_stmt: stmt -> location
  (** Returns the location of a {!Cil_types.stmt}.
      In case of a [Block] returns the location of its first localized
      statement.*)

val mkassign: lval -> exp -> location -> instr
val mkassign_statement: lval -> exp -> location -> stmt

(** determines if a var is local to a block. *)
val is_block_local: varinfo -> block -> bool

(* ************************************************************************** *)
(** {2 Types} *)
(* ************************************************************************** *)

val array_type: ?length:exp -> ?attr:attributes -> typ -> typ

val direct_array_size: typ -> int64
val array_size: typ -> int64
val direct_element_type: typ -> typ
val element_type: typ -> typ
val direct_pointed_type: typ -> typ
val pointed_type: typ -> typ

(* ************************************************************************** *)
(** {2 Functions} *)
(* ************************************************************************** *)

val is_function_type : varinfo -> bool
  (** Return [true] iff the type of the given varinfo is a function type. *)

(** Operations on cil function. *)
module Function: sig
  val formal_args: varinfo -> (string * typ * attributes) list
    (** Returns the list of the named formal arguments of a function.
	Never call on a variable of non functional type.*)

  val is_formal: varinfo -> fundec -> bool
  val is_local: varinfo -> fundec -> bool
  val is_formal_or_local: varinfo -> fundec -> bool
  val is_formal_of_prototype:
    varinfo (* to check *) -> varinfo (* of the prototype *) -> bool
    (** [is_formal_of_prototype v f] returns [true] iff [f] is a prototype and
	[v] is one of its formal parameters. *)

  val is_definition: cil_function -> bool
  val get_vi: cil_function -> varinfo
  val get_name: cil_function -> string
  val get_id: cil_function -> int
end

(* ************************************************************************** *)
(** {2 Predefined} *)
(* ************************************************************************** *)

val is_cea_function : string -> bool
val is_cea_dump_function : string -> bool
val is_cea_alloc : string -> bool
val is_cea_alloc_with_validity : string -> bool
val is_frama_c_builtin : string -> bool

(*
Local Variables:
compile-command: "make -C ../.."
End:
*)