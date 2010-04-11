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

open Cil_types

exception Not_less_than
exception Is_not_included

(** Generic lattice *)
module type Lattice = sig
  exception Error_Top
  exception Error_Bottom
  type t (** type of element of the lattice *)
  type widen_hint (** hints for the widening *)

  val equal: t -> t -> bool
  val join: t -> t -> t (** over-approximation of union *)
  val link: t -> t -> t (** under-approximation of union *)
  val meet: t -> t -> t (** under-approximation of intersection *)
  val narrow: t -> t -> t (** over-approximation of intersection *)
  val bottom: t (** the smallest *)
  val top: t  (** the largest *)

  val is_included: t -> t -> bool
  val is_included_exn: t -> t -> unit
  val intersects: t -> t -> bool
  val pretty: Format.formatter -> t -> unit

  val widen: widen_hint -> t -> t -> t
    (** [widen h t1 t2] is an over-approximation of [join t1 t2].
        Assumes [is_included t1 t2] *)

  val cardinal_zero_or_one: t -> bool

  (** [cardinal_less_than t v ]
      @raise Not_less_than whenever the cardinal of [t] is higher than [v] *)
  val cardinal_less_than: t -> int -> int

  val tag : t -> int

  module Datatype: Project.Datatype.S with type t = t

end

module type Lattice_With_Diff = sig
  include Lattice

  val diff : t -> t -> t
    (** [diff t1 t2] is an over-approximation of [t1-t2]. *)

  val diff_if_one : t -> t -> t
    (** [diff t1 t2] is an over-approximation of [t1-t2].
       Returns [t1] if [t2] is not a singleton. *)

  val fold_enum :
    split_non_enumerable:int -> (t -> 'a -> 'a) -> t -> 'a -> 'a
  val splitting_cardinal_less_than:
    split_non_enumerable:int -> t -> int -> int
  val hash : t -> int
  val pretty_debug : Format.formatter -> t -> unit
  val name : string
end

module type Lattice_Product = sig
  type t1
  type t2
  type tt = private Product of t1*t2 | Bottom
  include Lattice with type t = tt
  val inject : t1 -> t2 -> t
  val fst : t -> t1
  val snd : t -> t2
end

module type Lattice_Sum = sig
  type t1
  type t2
  type sum = private Top | Bottom | T1 of t1 | T2 of t2
  include Lattice with type t = sum
  val inject_t1 : t1 -> t
  val inject_t2 : t2 -> t
end

module type Lattice_Base = sig
  type l
  type tt = private Top | Bottom | Value of l
  include Lattice with type t = tt
  val project : t -> l
  val inject: l -> t
end

module type Lattice_Set = sig
  module O: Ptset.S
  type tt = private Set of O.t | Top
  include Lattice with type t = tt and type widen_hint = O.t
  val hash : t -> int
  val inject_singleton: O.elt -> t
  val inject: O.t -> t
  val empty: t
  val apply2: (O.elt -> O.elt -> O.elt) -> (t -> t -> t)
  val apply1: (O.elt -> O.elt) -> (t -> t)
  val fold: ( O.elt -> 'a -> 'a) -> t -> 'a -> 'a
  val iter: ( O.elt -> unit) -> t -> unit
  val project : t -> O.t
  val mem : O.elt -> t -> bool
end

module type Value = sig
  type t
  val name : string
(*  val id : t -> int *)
  val pretty : Format.formatter -> t -> unit
  val compare : t -> t -> int
  val hash: t -> int
  module Datatype: Project.Datatype.S with type t = t
end

module type Arithmetic_Value = sig
  include Value
  val gt : t -> t -> bool
  val le : t -> t -> bool
  val ge : t -> t -> bool
  val lt : t -> t -> bool
  val eq : t -> t -> bool
  val add : t -> t -> t
  val sub : t -> t -> t
  val mul : t -> t -> t
  val native_div : t -> t -> t
  val rem : t -> t -> t
  val pos_div : t -> t -> t
  val c_div : t -> t -> t
  val c_rem : t -> t -> t
  val cast: size:t -> signed:bool -> value:t -> t
  val abs : t -> t
  val zero : t
  val one : t
  val two : t
  val four : t
  val minus_one : t
  val is_zero : t -> bool
  val is_one : t -> bool
  val equal : t -> t -> bool
  val pgcd : t -> t -> t
  val ppcm : t -> t -> t
  val min : t -> t -> t
  val max : t -> t -> t
  val length : t -> t -> t (** b - a + 1 *)
  val of_int : int -> t
  val of_float : float -> t
  val of_int64 : Int64.t -> t
  val to_int : t -> int
  val to_float : t -> float
  val neg : t -> t
  val succ : t -> t
  val pred : t -> t
  val round_up_to_r : min:t -> r:t -> modu:t -> t
  val round_down_to_r : max:t -> r:t -> modu:t -> t
  val pos_rem : t -> t -> t
  val shift_left : t -> t -> t
  val shift_right : t -> t -> t
  val fold : (t -> 'a -> 'a) -> inf:t -> sup:t -> step:t -> 'a -> 'a
  val logand : t -> t -> t
  val logor : t -> t -> t
  val logxor : t -> t -> t
  val lognot : t -> t
  val power_two : int -> t
  val two_power : t -> t
  val extract_bits : with_alarms:CilE.warn_mode -> start:t -> stop:t -> t -> t
end

module Make_Lattice_Set(V:Value): Lattice_Set with type O.elt=V.t = struct
  exception Error_Top
  exception Error_Bottom
  module O =
    struct
      include Set.Make(V)
      let contains_single_elt s =
	try
	  let mi = min_elt s in
	  let ma = max_elt s in
	  if mi == ma
	  then (* exactly one elt *)
	    Some mi
	  else None
	with Not_found -> None
      let descr = Unmarshal.t_set_unchangedcompares V.Datatype.descr
	(* TODO: really unchangedcompares? *)
    end
  type tt = Set of O.t | Top
  type t = tt = Set of O.t | Top
  type y = O.t
  type widen_hint = O.t

  let bottom = Set O.empty
  let top = Top

  let hash c =
    match c with
      Top -> 12373
    | Set s ->
	let f v acc =
	  67 * acc + (V.hash v)
	in
	O.fold f s 17

  let tag = hash

  let compare e1 e2 =
    if e1==e2 then 0 else
      match e1,e2 with
        | Top,_ -> 1
        | _, Top -> -1
        | Set e1,Set e2 -> O.compare e1 e2

  let equal v1 v2 = compare v1 v2 = 0

  let widen _wh _t1 t2 = (* [wh] isn't used *)
    t2

  (** This is exact *)
  let meet v1 v2 =
    if v1 == v2 then v1 else
      match v1,v2 with
      | Top, v | v, Top -> v
      | Set s1 , Set s2 -> Set (O.inter s1 s2)

  (** This is exact *)
  let narrow = meet

  (** This is exact *)
  let join v1 v2 =
    if v1 == v2 then v1 else
      match v1,v2 with
      | Top, _ | _, Top -> Top
      | Set s1 , Set s2 ->
          let u = O.union s1 s2 in
          Set u

  (** This is exact *)
  let link = join

  let cardinal_less_than s n =
    match s with
      Top -> raise Not_less_than
    | Set s ->
	let c = O.cardinal s in
	if  c > n
	then raise Not_less_than;
	c

  let cardinal_zero_or_one s =
    try
      ignore (cardinal_less_than s 1) ; true
    with Not_less_than -> false

  let inject s = Set s
  let inject_singleton e = inject (O.singleton e)
  let empty = inject O.empty

  let transform f = fun t1 t2 ->
    match t1,t2 with
      | Top, _ | _, Top -> Top
      | Set v1, Set v2 -> Set (f v1 v2)

  let map_set f s =
    O.fold
      (fun v -> O.add (f v))
      s
      O.empty

  let apply2 f s1 s2 =
    let distribute_on_elements f s1 s2 =
      O.fold
        (fun v -> O.union (map_set (f v) s2))
        s1
        O.empty
    in
    transform (distribute_on_elements f) s1 s2

  let apply1 f s = match s with
    | Top -> top
    | Set s -> Set(map_set f s)

  let pretty fmt t =
    match t with
      | Top -> Format.fprintf fmt "TopSet"
      | Set s ->
          if O.is_empty s then Format.fprintf fmt "BottomSet"
          else begin
            Format.fprintf fmt "@[{@[%a@]}@]"
              (fun fmt s ->
		 O.iter
                   (Format.fprintf fmt "@[%a;@]@ " V.pretty) s) s
          end

  let is_included t1 t2 =
    (t1 == t2) ||
      match t1,t2 with
      | _,Top -> true
      | Top,_ -> false
      | Set s1,Set s2 -> O.subset s1 s2

  let is_included_exn v1 v2 =
    if not (is_included v1 v2) then raise Is_not_included

  let intersects t1 t2 =
    let b = match t1,t2 with
      | _,Top | Top,_ -> true
      | Set s1,Set s2 ->
          O.exists (fun e -> O.mem e s2) s1
    in
    (* Format.printf
       "[Lattice_Set]%a intersects %a: %b @\n"
       pretty t1 pretty t2 b;*)
    b

  let fold f elt init =
    match elt with
      | Top -> raise Error_Top
      | Set v -> O.fold f v init


  let iter f elt =
    match elt with
      | Top -> raise Error_Top
      | Set v -> O.iter f v

  let project o = match o with
    | Top -> raise Error_Top
    | Set v -> v

  let mem v s = match s with
  | Top -> true
  | Set s -> O.mem v s

  module Datatype =
    Project.Datatype.Register
      (struct
	 type t = tt
	 let copy _ = assert false
	 open Unmarshal
	 let descr = Structure (Sum [| [| O.descr |] |])
	 let name = Project.Datatype.extend_name "lattice_set" V.Datatype.name
       end)
  let () = Datatype.register_comparable ~hash:tag ~equal ~compare ()

end

module Make_Hashconsed_Lattice_Set(V: Ptset.Id_Datatype)
  : Lattice_Set with type O.elt=V.t =
struct
  exception Error_Top
  exception Error_Bottom
  module O = Ptset.Make(V)
  type tt = Set of O.t | Top
  type t = tt = Set of O.t | Top
  type y = O.t
  type widen_hint = O.t

  let bottom = Set O.empty
  let top = Top

  let hash c =
    match c with
      Top -> 12373
    | Set s ->
	let f v acc =
	  67 * acc + (V.id v)
	in
	O.fold f s 17

  let tag = hash

  let equal e1 e2 =
    if e1==e2 then true
    else
      match e1,e2 with
      | Top,_ | _, Top -> false
      | Set e1,Set e2 -> O.equal e1 e2

  let widen _wh _t1 t2 = (* [wh] isn't used *)
    t2

  (** This is exact *)
  let meet v1 v2 =
    if v1 == v2 then v1 else
      match v1,v2 with
      | Top, v | v, Top -> v
      | Set s1 , Set s2 -> Set (O.inter s1 s2)

  (** This is exact *)
  let narrow = meet

  (** This is exact *)
  let join v1 v2 =
    if v1 == v2 then v1 else
      match v1,v2 with
      | Top, _ | _, Top -> Top
      | Set s1 , Set s2 ->
          let u = O.union s1 s2 in
          Set u

  (** This is exact *)
  let link = join

  let cardinal_less_than s n =
    match s with
      Top -> raise Not_less_than
    | Set s ->
	let c = O.cardinal s in
	if  c > n
	then raise Not_less_than;
	c

  let cardinal_zero_or_one s =
    try
      ignore (cardinal_less_than s 1) ; true
    with Not_less_than -> false

  let inject s = Set s
  let inject_singleton e = inject (O.singleton e)
  let empty = inject O.empty

  let transform f = fun t1 t2 ->
    match t1,t2 with
      | Top, _ | _, Top -> Top
      | Set v1, Set v2 -> Set (f v1 v2)

  let map_set f s =
    O.fold
      (fun v -> O.add (f v))
      s
      O.empty

  let apply2 f s1 s2 =
    let distribute_on_elements f s1 s2 =
      O.fold
        (fun v -> O.union (map_set (f v) s2))
        s1
        O.empty
    in
    transform (distribute_on_elements f) s1 s2

  let apply1 f s = match s with
    | Top -> top
    | Set s -> Set(map_set f s)

  let pretty fmt t =
    match t with
      | Top -> Format.fprintf fmt "TopSet"
      | Set s ->
          if O.is_empty s then Format.fprintf fmt "BottomSet"
          else begin
            Format.fprintf fmt "@[{@[%a@]}@]"
              (fun fmt s ->
		 O.iter
                   (Format.fprintf fmt "@[%a;@]@ " V.pretty) s) s
          end

  let is_included t1 t2 =
    (t1 == t2) ||
      match t1,t2 with
      | _,Top -> true
      | Top,_ -> false
      | Set s1,Set s2 -> O.subset s1 s2

  let is_included_exn v1 v2 =
    if not (is_included v1 v2) then raise Is_not_included

  let intersects t1 t2 =
    let b = match t1,t2 with
      | _,Top | Top,_ -> true
      | Set s1,Set s2 ->
          O.exists (fun e -> O.mem e s2) s1
    in
    (* Format.printf
       "[Lattice_Set]%a intersects %a: %b @\n"
       pretty t1 pretty t2 b;*)
    b

  let fold f elt init =
    match elt with
      | Top -> raise Error_Top
      | Set v -> O.fold f v init


  let iter f elt =
    match elt with
      | Top -> raise Error_Top
      | Set v -> O.iter f v

  let project o = match o with
    | Top -> raise Error_Top
    | Set v -> v

  let mem v s = match s with
  | Top -> true
  | Set s -> O.mem v s


  module Datatype =
    Project.Datatype.Register
      (struct
	 type t = tt = Set of O.t | Top
	 let copy _ = assert false
	 open Unmarshal
	 let descr = Structure(Sum [| [| O.descr |] |])
	 let name = Project.Datatype.extend_name
	     "hashconsed_lattice_set" V.Datatype.name
       end)
  let () = Datatype.register_comparable ~hash:tag ~equal ()

end

module Make_Pair (V:Value) (W:Value)=
struct

  type t = V.t*W.t

  let compare (a,b as p) (a',b' as p') =
    if p==p' then 0 else
      let c = V.compare a a' in
      if c=0 then W.compare b b' else c

  let pretty fmt (a,b) =
    Format.fprintf fmt "(%a,%a)" V.pretty a W.pretty b

  let hash (b,e) = V.hash b + 1351 * (W.hash e)
  let equal a b  = compare a b = 0

  module Datatype =
    Project.Datatype.Register
      (struct
	 type tt = t
	type t = tt
	let copy _ = assert false (* TODO *)
	open Unmarshal
	let descr =
	  Structure (Sum [| [| V.Datatype.descr; W.Datatype.descr |] |])
	let name =
	  Project.Datatype.extend_name2
	    "lattice_pair" V.Datatype.name W.Datatype.name
      end)
  let () = Datatype.register_comparable ~hash ~equal ()

end

let rec compare_list compare_elt l1 l2 =
  if l1==l2 then 0 else
    match l1,l2 with
      | [], _ -> 1
      | _, [] -> -1
      | v1::r1,v2::r2 ->
          let c = compare_elt v1 v2 in
          if c=0 then compare_list compare_elt r1 r2 else c

module Make_Lattice_Interval_Set (V:Arithmetic_Value) =
struct
  exception Error_Top
  exception Error_Bottom
  module Interval = Make_Pair (V) (V)
  type elt = Interval.t

  type tt = Top | Set of elt list
  type t = tt

  type widen_hint = unit

  let bottom = Set []
  let top = Top

  let check t =
    assert (match t with
            | Top -> true
            | Set s ->
                let last_stop = ref None in
                List.for_all
                  (fun (a,b) -> V.compare a b <= 0 &&
                     match !last_stop with
                       None -> last_stop := Some b; true
                     | Some l -> last_stop := Some b; V.gt a l)
                  s) ;
    t

  let hash l = match l with
    Top -> 667
  | Set l ->
      List.fold_left
	(fun acc p -> 371 * acc + Interval.hash p)
	443
	l

  let tag = hash

  let cardinal_zero_or_one v =
    match v with
      Top -> false
    | Set [x,y] -> V.eq x y
    | Set _ -> false

  let cardinal_less_than v n =
    match v with
      Top -> raise Not_less_than
    | Set l ->
	let rec aux l card = match l with
	  [] -> card
	| (x,y)::t ->
	    let nn = V.of_int n in
	    let card = V.add card ((V.succ (V.sub y x))) in
	    if V.gt card nn
	    then raise Not_less_than
	    else aux t card
	in
	V.to_int (aux l V.zero)

  let splitting_cardinal_less_than ~split_non_enumerable _v _n =
    ignore (split_non_enumerable);
    assert false

  let compare e1 e2 =
    if e1==e2 then 0 else
      match e1,e2 with
        | Top,_ -> 1
        | _, Top -> -1
        | Set e1, Set e2 ->
            compare_list Interval.compare e1 e2

  let equal e1 e2 = compare e1 e2 = 0

  let pretty fmt t =
    match t with
      | Top -> Format.fprintf fmt "TopISet"
      | Set s ->
          if s=[] then Format.fprintf fmt "BottomISet"
          else begin
            Format.fprintf fmt "{%a}"
              (fun fmt s ->
		 List.iter
                   (fun (b,e) ->
                      Format.fprintf
			fmt
			"[%a..%a]; "
			V.pretty b
			V.pretty e
                   )
                   s)
              s
          end

  let widen _wh t1 t2  =  (if equal t1 t2 then t1 else top)

  let meet v1 v2 =
    if v1 == v2 then v1 else

	(match v1,v2 with
	 | Top, v | v, Top -> v
	 | Set s1 , Set s2 -> Set (
	     let rec aux acc (l1:elt list) (l2:elt list) = match l1,l2 with
	     | [],_|_,[] -> List.rev acc
             | (((b1,e1)) as i1)::r1,
		 (((b2,e2)) as i2)::r2 ->
		 let c = V.compare b1 b2 in
		 if c = 0 then (* intervals start at the same value *)
                   let ce = V.compare e1 e2 in
                   if ce=0 then
                     aux ((b1,e1)::acc) r1 r2 (* same intervals *)
                   else
                     (* one interval is included in the other *)
                     let min,not_min,min_tail,not_min_tail =
                       if ce > 0 then i2,i1,r2,r1 else
			 i1,i2,r1,r2
                     in
                     aux ((min)::acc) min_tail
                       (((
                           (snd (min),
                            snd (not_min))))::
                          not_min_tail)
		 else (* intervals start at different values *)
                   let _min,min_end,not_min_begin,min_tail,not_min_from =
                     if c > 0
                     then b2,e2,b1,r2,l1
                     else b1,e1,b2,r1,l2
                   in
                   let c_min = V.compare min_end not_min_begin in
                   if c_min >= 0 then
                     (* intersecting intervals *)
                     aux acc
		       ((
			  (not_min_begin,min_end))
			::min_tail)
                       not_min_from
                   else
                     (* disjoint intervals *)
                     aux acc min_tail not_min_from
             in aux [] s1 s2))

  let join v1 v2 =
    if v1 == v2 then v1 else
      (match v1,v2 with
       | Top, _ | _, Top -> Top
       | Set (s1:elt list) , Set (s2:elt list) ->
	   let rec aux (l1:elt list) (l2:elt list) = match l1,l2 with
           | [],l|l,[] -> l
           | (b1,e1)::r1,(b2,e2)::r2 ->
               let c = V.compare b1 b2 in
               let min_begin,min_end,min_tail,not_min_from =
                 if c >= 0 then b2,e2,r2,l1
                 else b1,e1,r1,l2
               in
               let rec enlarge_interval stop l1 look_in_me =
                 match look_in_me with
                 | [] -> stop,l1,[]
                 | ((b,e))::r ->
                     if V.compare stop (V.pred b) >= 0
                     then
                       if V.compare stop e >= 0
                       then enlarge_interval  stop l1 r
                       else enlarge_interval  e r l1
                     else stop,l1,look_in_me
               in
               let stop,new_l1,new_l2 =
                 enlarge_interval
                   min_end
                   min_tail
                   not_min_from
               in ((min_begin,stop))::
                    (aux new_l1 new_l2)
	   in Set (aux s1 s2))

  let inject l =  (Set l)

  let inject_one ~size ~value =
    (inject [value,V.add value (V.pred size)])

  let inject_bounds min max =
    if V.le min max
    then inject [min,max]
    else bottom

  let transform _f = (* f must be non-decreasing *)
    assert false

  let apply2 _f _s1 _s2 = assert false

  let apply1 _f _s = assert false

  let is_included t1 t2 =
    (t1 == t2) ||
      match t1,t2 with
      | _,Top -> true
      | Top,_ -> false
      | Set s1,Set s2 ->
          let rec aux l1 l2 = match l1 with
          | [] -> true
          | i::r ->
              let rec find (b,e as arg) l =
		match l with
		| [] -> raise Not_found
		| (b',e')::r ->
                    if V.compare b b' >= 0
                      && V.compare e' e >= 0
                    then  l
                    else if V.compare e' b >= 0 then
                      raise Not_found
                    else find arg r
              in
              try aux r (find i l2)
              with Not_found -> false
          in
          aux s1 s2

  let link t1 t2 = join t1 t2 (* join is in fact an exact union *)

  let is_included_exn v1 v2 =
    if not (is_included v1 v2) then raise Is_not_included

  let intersects t1 t2 =
    let m = meet t1 t2 in
    not (equal m bottom)

  let fold f v acc =
    match v with
      | Top -> raise Error_Top
      | Set s ->
          List.fold_right f s acc

  let narrow = meet

  module Datatype =
    Project.Datatype.Register
      (struct
	 type t = tt
	 let copy _ = assert false (* TODO *)
	 let descr = Unmarshal.Abstract (* TODO: use Data.descr *)
	 let name =
	   Project.Datatype.extend_name
	     "lattice_interval_set" Interval.Datatype.name
       end)
  let () = Datatype.register_comparable ~hash ~equal ()

end

module Make_Lattice_Base (V:Value):(Lattice_Base with type l = V.t) = struct

  type l = V.t
  type tt = Top | Bottom | Value of l
  type t = tt
  type y = l
  type widen_hint = V.t list

  let bottom = Bottom
  let top = Top

  exception Error_Top
  exception Error_Bottom
  let project v = match v with
    | Top  -> raise Error_Top
    | Bottom -> raise Error_Bottom
    | Value v -> v


  let cardinal_zero_or_one v = match v with
    | Top  -> false
    | _ -> true

  let cardinal_less_than v n = match v with
    | Top  -> raise Not_less_than
    | Value _ -> if n >= 1 then 1 else raise Not_less_than
    | Bottom -> 0

  let compare e1 e2 =
    if e1==e2 then 0 else
      match e1,e2 with
        | Top,_ -> 1
        | _, Top -> -1
        | Bottom, _ -> -1
        | _, Bottom -> 1
        | Value e1,Value e2 -> V.compare e1 e2
  let equal v1 v2 = compare v1 v2 = 0

  let tag = function
    | Top -> 3
    | Bottom -> 5
    | Value v -> V.hash v * 7

  let widen _wh t1 t2 = (* [wh] isn't used yet *)
    if equal t1 t2 then t1 else top

  (** This is exact *)
  let meet b1 b2 =
    if b1 == b2 then b1 else
    match b1,b2 with
    | Bottom, _ | _, Bottom -> Bottom
    | Top , v | v, Top -> v
    | Value v1, Value v2 -> if (V.compare v1 v2)=0 then b1 else Bottom

  (** This is exact *)
  let narrow = meet

  (** This is exact *)
  let join b1 b2 =
    if b1 == b2 then b1 else
      match b1,b2 with
      | Top, _ | _, Top -> Top
      | Bottom , v | v, Bottom -> v
      | Value v1, Value v2 -> if (V.compare v1 v2)=0 then b1 else Top

  (** This is exact *)
  let link = join

  let inject x = Value x

  let transform f = fun t1 t2 ->
    match t1,t2 with
      | Bottom, _ | _, Bottom -> Bottom
      | Top, _ | _, Top -> Top
      | Value v1, Value v2 -> Value (f v1 v2)

  let pretty fmt t =
    match t with
      | Top -> Format.fprintf fmt "Top"
      | Bottom ->  Format.fprintf fmt "Bottom"
      | Value v -> Format.fprintf fmt "<%a>" V.pretty v

  let is_included t1 t2 =
    let b = (t1 == t2) ||
      (equal (meet t1 t2) t1)
    in
    (* Format.printf
       "[Lattice]%a is included in %a: %b @\n"
       pretty t1 pretty t2 b;*)
    b

  let is_included_exn v1 v2 =
    if not (is_included v1 v2) then raise Is_not_included

  let intersects t1 t2 = not (equal (meet t1 t2) Bottom)

  module Datatype =
    Project.Datatype.Register
      (struct
	 type t = tt = Top | Bottom | Value of l
	 let copy _ = assert false (* TODO *)
	 open Unmarshal
	 let descr = Structure (Sum [| [| V.Datatype.descr |] |])
	 let name = Project.Datatype.extend_name "lattice_base" V.Datatype.name
       end)
  let () = Datatype.register_comparable ~hash:tag ~equal ()

end

module Int = struct
  open My_bigint
  type t = big_int
  let descr = Unmarshal.Abstract

  module Datatype = Datatype.BigInt
  let name = Datatype.name

  let zero = zero_big_int
  let one = unit_big_int
  let two = succ_big_int one
  let four = big_int_of_int 4
  let eight = big_int_of_int 8
  let rem = mod_big_int
  let div = div_big_int
  let mul = mult_big_int
  let sub = sub_big_int
  let abs = abs_big_int
  let succ = succ_big_int
  let pred = pred_big_int
  let neg = minus_big_int
  let add = add_big_int

  let billion_one = big_int_of_int 1000000001
  let hash c =
    let i =
      try
	int_of_big_int c
      with Failure _ -> int_of_big_int (rem c billion_one)
    in
    197 + i

  let tag = hash
  let equal a b = eq_big_int a b

  let log_shift_right = log_shift_right_big_int
  let shift_right = shift_right_big_int
  let shift_left = shift_left_big_int

  let logand = land_big_int
  let lognot = lnot_big_int
  let logor = lor_big_int
  let logxor = lxor_big_int

  let le = le_big_int
  let lt = lt_big_int
  let ge = ge_big_int
  let gt = gt_big_int
  let eq = eq_big_int
  let neq x y = not (eq_big_int x y)

  let to_int v =
    try int_of_big_int v
    with Failure "int_of_big_int" -> assert false
  let of_int i = big_int_of_int i
  let of_int64 i = big_int_of_string (Int64.to_string i)
  let to_int64 i = Int64.of_string (string_of_big_int i)
  let of_string = big_int_of_string
  let to_string = string_of_big_int
  let to_float = float_of_big_int
  let of_float _ = assert false

  let minus_one = pred zero
  let pretty fmt i = Format.pp_print_string fmt (string_of_big_int i)
  let pretty_debug = pretty

  let pretty_s () = string_of_big_int
  let is_zero v = (sign_big_int v) = 0

  let compare = compare_big_int
  let is_one v = eq one v
  let pos_div  = div
  let pos_rem = rem
  let native_div = div
  let c_div u v =
    let bad_div = div u v in
    if (lt u zero) && neq zero (rem u v) then
      if lt v zero
      then pred bad_div
      else succ bad_div
    else bad_div
  let c_rem u v =
    sub u (mul v (c_div u v))

  let cast ~size ~signed ~value =
    let factor = two_power size in
    let mask = two_power (sub size one) in

    if (not signed) then pos_rem value factor
    else
      if equal (logand mask value) zero
    then logand value (pred mask)
    else
      logor (lognot (pred mask)) value

  let two_power = My_bigint.two_power

  let power_two = My_bigint.power_two

  let extract_bits ~with_alarms:_ ~start ~stop v =
    assert (ge start zero && ge stop start);
    (*Format.printf "%a[%a..%a]@\n" pretty v pretty start pretty stop;*)
    let r = bitwise_extraction (to_int start) (to_int stop) v in
      (*Format.printf "%a[%a..%a]=%a@\n" pretty v pretty start pretty stop pretty r;*)
      r

      (*

        include Int64
        let pretty fmt i = Format.fprintf fmt "%Ld" i
        let pretty_s () i = Format.sprintf  "%Ld" i
        let is_zero v = 0 = (compare zero v)
        let lt = (<)
        let le = (<=)
        let neq = (<>)
        let eq = (=)
        let gt = (>)
        let ge = (>=)

        let shift_left x y = shift_left x (to_int y)
        let shift_right x y = shift_right x (to_int y)
        let log_shift_right x y =  shift_right_logical x (to_int y)
        let of_int64 x = x
        let to_int64 x = x

        let pos_div u v =
        let bad_div = div u v in
        let bad_rem = rem u v in
        if compare bad_rem zero >= 0
        then bad_div
        else (sub bad_div one)

        let pos_rem x m =
        let r = rem x m in
        if lt r zero then add r m (* cannot overflow because r and m
        have different signs *)
        else r

        let c_div = div

      *)

  let is_even v = is_zero (logand one v)

  (** [pgcd u 0] is allowed and returns [u] *)
  let pgcd u v =
    let rec spec_pgcd u v = (* initial implementation viewed as the spec *)
      if is_zero v
      then u
      else spec_pgcd v (rem u v) in
  (*  let abs_max_min u v =
         if compare (abs u) (abs v) >= 0 then (u, v) else (v, u) in
    let impl_pgcd u v =
      let rec ordered_pgcd (u, v) =
        assert (compare (abs u) (abs v) >= 0); (* [pgcd (u, v)] such as (abs v) <= (abs u) *)
        if is_zero v
        then u
        else (* both differ from zero *)
          let rec none_zero_pcgd u v =
            assert (not (is_zero u));
            assert (not (is_zero v));
            let (u, v) = abs_max_min u v in
              ordered_pgcd (v, (rem u v)) in
            match (is_even u, is_even v) with
                (true, true) -> (* both are even: pgcd(2*a,2*b)=2*pgcd(a,b) *)
                  let u_div_2 = shift_right u one
                  and v_div_2 = shift_right v one
                  in shift_left (ordered_pgcd (v_div_2, (rem u_div_2 v_div_2))) one
              | (true, false) -> (* only u is even: pgcd(2*a,2*b+1)=pgcd(a,2*b+1) *)
                  let u_div_2 = shift_right u one
                  in none_zero_pcgd v u_div_2
              | (false, true) -> (* only v is even: pgcd(2*a,2*b+1)=pgcd(a,2*b+1) *)
                  let v_div_2 = shift_right v one
                  in none_zero_pcgd v_div_2 u
              | (false, false) -> (* none are even *)
                  ordered_pgcd (v, (rem u v)) in
        ordered_pgcd (abs_max_min u v) in
  *)
    (* let r = impl_pgcd u v in *)
    let r =
      if is_zero v
      then u
      else (* impl_pgcd *) gcd_big_int u v in
    assert (0 = (compare r (spec_pgcd v u))) ; (* compliance with the spec *)
      r


  let ppcm u v =
    if u = zero || v = zero
    then zero
    else native_div (mul u v) (pgcd u v)

  let length u v = succ (sub v u)

  let min u v     = if compare u v  >= 0 then v else u
  let max u v     = if compare u v  >= 0 then u else v

  let round_down_to_zero v modu =
    mul (pos_div v modu) modu

  (** [round_up_to_r m r modu] is the smallest number [n] such that
	 [n]>=[m] and [n] = [r] modulo [modu] *)
  let round_up_to_r ~min:m ~r ~modu =
    add (add (round_down_to_zero (pred (sub m r)) modu) r) modu

  (** [round_down_to_r m r modu] is the largest number [n] such that
     [n]<=[m] and [n] = [r] modulo [modu] *)
  let round_down_to_r ~max:m ~r ~modu =
    add (round_down_to_zero (sub m r) modu) r

  (** execute [f] on [inf], [inf + step], ... *)
  let fold f ~inf ~sup ~step acc =
(*    Format.printf "Int.fold: inf:%a sup:%a step:%a@\n"
       pretty inf pretty sup pretty step; *)
    let nb_loop = div (sub sup inf) step in
    let next = add step in
    let rec fold ~counter ~inf acc =
        if eq counter (of_int 1000) then
          CilE.warn_once "enumerating %s integers" (to_string nb_loop);
        if le inf sup
	then begin
(*          Format.printf "Int.fold: %a@\n" pretty inf; *)
          fold ~counter:(succ counter) ~inf:(next inf) (f inf acc)
	  end
        else acc
      in
    fold ~counter:zero ~inf acc

end

module type Key = sig
  type t
  val compare : t -> t -> int
  val equal : t -> t -> bool
  val pretty : Format.formatter -> t -> unit
  val is_null : t -> bool
  val null : t
  val hash : t -> int
  val id : t -> int
  val name : string
  module Datatype : Project.Datatype.S with type t = t
end

module VarinfoSetLattice = Make_Hashconsed_Lattice_Set
  (struct
     open Cil_types
     type t = varinfo
     module Datatype = Cil_datatype.Varinfo
     let compare v1 v2 = compare v1.vid v2.vid
     let equal v1 v2 = v1.vid = v2.vid
     let pretty fmt v =
       Format.fprintf fmt "@[%a@]" !Ast_printer.d_ident v.vname
     let hash v = v.vid
     let id v = v.vid
     let name = "varinfo"
   end)

module LocationSetLattice = struct
  include Make_Lattice_Set
    (struct
       type t = Cil_types.location
       let name = "source location"
       module Datatype = Cil_datatype.Location
       let compare = Pervasives.compare
       let pretty fmt (b,_e) =
         Format.fprintf fmt "@[%s:%d@]" b.Lexing.pos_fname b.Lexing.pos_lnum
       let hash (b,_e) = Hashtbl.hash (b.Lexing.pos_fname,b.Lexing.pos_lnum)
     end)
  let currentloc_singleton () = inject_singleton (Cil.CurrentLoc.get ())
end

module type Collapse = sig
  val collapse : bool
end

(** If [C.collapse] then [L1.Bottom,_ = _,L2.Bottom = Bottom] *)
module Make_Lattice_Product(L1:Lattice)(L2:Lattice)(C:Collapse):
  (Lattice_Product with type t1 =  L1.t and type t2 = L2.t) =
struct

  exception Error_Top
  exception Error_Bottom
  type t1 = L1.t
  type t2 = L2.t
  type tt = Product of t1*t2 | Bottom
  type t = tt
  type widen_hint = L1.widen_hint * L2.widen_hint

  let tag = function
    | Bottom -> 3
    | Product(v1, v2) -> L1.tag v1 + 3 * L2.tag v2

  let cardinal_less_than _ = assert false

  let cardinal_zero_or_one v = match v with
    | Bottom -> true
    | Product (t1, t2) ->
	(L1.cardinal_zero_or_one t1) &&
	  (L2.cardinal_zero_or_one t2)

(*  let compare x x' =
    if x == x' then 0 else
      match x,x' with
      | Bottom, Bottom -> 0
      | Bottom, Product _ -> 1
      | Product _,Bottom -> -1
      | (Product (a,b)), (Product (a',b')) ->
	  let c = L1.compare a a' in
	  if c = 0 then L2.compare b b' else c
*)
  let equal x x' =
    if x == x' then true else
      match x,x' with
      | Bottom, Bottom -> true
      | Bottom, Product _ -> false
      | Product _,Bottom -> false
      | (Product (a,b)), (Product (a',b')) ->
	  L1.equal a a'  && L2.equal b b'

  let top = Product(L1.top,L2.top)

  let bottom = Bottom

  let fst x = match x with
    Bottom -> L1.bottom
  | Product(x1,_) -> x1

  let snd x = match x with
    Bottom -> L2.bottom
  | Product(_,x2) -> x2

  let condition_to_be_bottom x1 x2 =
    let c1 = (L1.equal x1 L1.bottom)  in
    let c2 = (L2.equal x2 L2.bottom)  in
    (C.collapse && (c1 || c2)) || (not C.collapse && c1 && c2)

  let inject x y =
    if condition_to_be_bottom x y
    then bottom
    else Product(x,y)

  let widen (wh1, wh2) t l =
    let t1 = fst t in
    let t2 = snd t in
    let l1 = fst l in
    let l2 = snd l in
    inject (L1.widen wh1 t1 l1) (L2.widen wh2 t2 l2)

  let join x1 x2 =
    if x1 == x2 then x1 else
      match x1,x2 with
      | Bottom, v | v, Bottom -> v
      | Product (l1,ll1), Product (l2,ll2) ->
	  Product(L1.join l1 l2, L2.join ll1 ll2)

  let link _ = assert false (** Not implemented yet. *)

  let narrow _ = assert false (** Not implemented yet. *)

  let meet x1 x2 =
    if x1 == x2 then x1 else
    match x1,x2 with
    | Bottom, _ | _, Bottom -> Bottom
    | Product (l1,ll1), Product (l2,ll2) ->
	let l1 = L1.meet l1 l2 in
	let l2 = L2.meet ll1 ll2 in
        inject l1 l2

  let pretty fmt x =
    match x with
      Bottom ->
	Format.fprintf fmt "BotProd"
    | Product(l1,l2) ->
	Format.fprintf fmt "(%a,%a)" L1.pretty l1 L2.pretty l2

  let intersects  x1 x2 =
    match x1,x2 with
    | Bottom, _ | _, Bottom -> false
    | Product (l1,ll1), Product (l2,ll2) ->
	(L1.intersects l1 l2) && (L2.intersects ll1 ll2)

  let is_included x1 x2 =
    (x1 == x2) ||
    match x1,x2 with
    | Bottom, _ -> true
    | _, Bottom -> false
    | Product (l1,ll1), Product (l2,ll2) ->
	(L1.is_included l1 l2) && (L2.is_included ll1 ll2)

  let is_included_exn x1 x2 =
    if x1 != x2
    then
      match x1,x2 with
      | Bottom, _ -> ()
      | _, Bottom -> raise Is_not_included
      | Product (l1,ll1), Product (l2,ll2) ->
	  L1.is_included_exn l1 l2;
	  L2.is_included_exn ll1 ll2

  let transform _f (_l1,_ll1) (_l2,_ll2) =
    raise (Invalid_argument "Abstract_interp.Make_Lattice_Product.transform")

  module Datatype =
    Project.Datatype.Register
      (struct
	 type t = tt = Product of t1*t2 | Bottom
	 let copy _ = assert false (* TODO *)
	 open Unmarshal
	 let descr =
	   Structure (Sum [| [| L1.Datatype.descr; L2.Datatype.descr |] |])
	 let name =
	   Project.Datatype.extend_name2
	     "lattice_product" L1.Datatype.name L2.Datatype.name
       end)
  let () = Datatype.register_comparable ~hash:tag ~equal ()

end

module Make_Lattice_Sum (L1:Lattice) (L2:Lattice):
  (Lattice_Sum with type t1 = L1.t and type t2 = L2.t)
  =
struct
  exception Error_Top
  exception Error_Bottom
  type t1 = L1.t
  type t2 = L2.t
  type sum = Top | Bottom | T1 of t1 | T2 of t2
  type t = sum
  type y = t
  type widen_hint = L1.widen_hint * L2.widen_hint

  let top = Top
  let bottom = Bottom

  let tag = function
    | Top -> 3
    | Bottom -> 5
    | T1 t -> 7 * L1.tag t
    | T2 t -> - 17 * L2.tag t

  let cardinal_less_than _ = assert false

  let cardinal_zero_or_one v = match v with
    | Top  -> false
    | Bottom -> true
    | T1 t1 -> L1.cardinal_zero_or_one t1
    | T2 t2 -> L2.cardinal_zero_or_one t2

  let widen (wh1, wh2) t1 t2 =
    match t1,t2 with
      | T1 x,T1 y ->
          T1 (L1.widen wh1 x y)
      | T2 x,T2 y ->
          T2 (L2.widen wh2 x y)
      | Top,Top | Bottom,Bottom -> t1
      | _,_ -> Top

(*  let compare u v =
    if u == v then 0 else
      match u,v with
      | Top,Top | Bottom,Bottom -> 0
      | Bottom,_ | _,Top -> 1
      | Top,_ |_,Bottom -> -1
      | T1 _ , T2 _ -> 1
      | T2 _ , T1 _ -> -1
      | T1 t1,T1 t1' -> L1.compare t1 t1'
      | T2 t1,T2 t1' -> L2.compare t1 t1'
*)

  let equal _x _y = assert false (* todo *)

  let inject _ = assert false

  (** Forbid [L1 Bottom] *)
  let inject_t1 x =
    if L1.equal x L1.bottom then Bottom
    else T1 x

  (** Forbid [L2 Bottom] *)
  let inject_t2 x =
    if L2.equal x L2.bottom then Bottom
    else T2 x

  let pretty fmt v =
    match v with
      | T1 x -> L1.pretty fmt x
      | T2 x -> L2.pretty fmt x
      | Top -> Format.fprintf fmt "<TopSum>"
      | Bottom -> Format.fprintf fmt "<BottomSum>"

  let join u v =
    if u == v then u else
      match u,v with
      | T1 t1,T1 t2 -> T1 (L1.join t1 t2)
      | T2 t1,T2 t2 -> T2 (L2.join t1 t2)
      | Bottom,x| x,Bottom -> x
      | _,_ ->
          (*Format.printf
            "Degenerating collision : %a <==> %a@\n" pretty u pretty v;*)
          top

  let link _ = assert false (** Not implemented yet. *)

  let narrow _ = assert false (** Not implemented yet. *)

  let meet u v =
    if u == v then u else
    match u,v with
      | T1 t1,T1 t2 -> inject_t1 (L1.meet t1 t2)
      | T2 t1,T2 t2 -> inject_t2 (L2.meet t1 t2)
      | (T1 _ | T2 _),Top -> u
      | Top,(T1 _ | T2 _) -> v
      | Top,Top -> top
      | _,_ -> bottom

  let intersects u v =
    match u,v with
      | Bottom,_ | _,Bottom -> false
      | Top,_ |_,Top -> true
      | T1 _,T1 _ -> true
      | T2 _,T2 _ -> true
      | _,_ -> false

  let is_included u v =
    (u == v) ||
    let b = match u,v with
    | Bottom,_ | _,Top -> true
    | Top,_ | _,Bottom -> false
    | T1 t1,T1 t2 -> L1.is_included t1 t2
    | T2 t1,T2 t2 -> L2.is_included t1 t2
    | _,_ -> false
    in
    (* Format.printf
      "[Lattice_Sum]%a is included in %a: %b @\n" pretty u pretty v b;*)
    b

  let is_included_exn v1 v2 =
    if not (is_included v1 v2) then raise Is_not_included

  let transform _f _u _v = assert false

  module Datatype =
    Project.Datatype.Register
      (struct
	 type t = sum
	 let copy _ = assert false (* TODO *)
	 let descr = Project.no_descr
	 let name =
	   Project.Datatype.extend_name2 "lattice_sum"
	     L1.Datatype.name L2.Datatype.name
       end)
  let () = Datatype.register_comparable ~hash:tag ~equal ()

end