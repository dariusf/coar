open Core
open Common
open Util
open Ast
open LogicOld

let update_term_map ?(d=0) sort terms term_map =
  if d = 0 then term_map 
  else
    match sort with
    | T_array.SArray (si, se) -> 
      let si_terms = begin match Map.Poly.find term_map si with | Some si_terms-> si_terms | None -> Set.Poly.empty end in
      let se_terms = begin match Map.Poly.find term_map se with | Some se_terms-> se_terms | None -> Set.Poly.empty end in
      let store_terms = Set.Poly.fold terms ~init:Set.Poly.empty ~f:(
          fun ret t ->  Set.Poly.fold si_terms ~init:ret ~f:(
              fun ret si_term  -> Set.Poly.fold se_terms ~init:ret ~f:(
                  fun ret se_term -> Set.Poly.add ret @@ T_array.mk_store t si_term se_term ))) |> Set.Poly.union terms in
      let select_terms = Set.Poly.fold terms ~init:Set.Poly.empty ~f:(
          fun ret t -> Set.Poly.union ret @@ Set.Poly.map si_terms ~f:(fun si_term -> T_array.mk_select t si_term)) |> Set.Poly.union (se_terms) in
      Map.Poly.set term_map ~key:sort ~data:store_terms |> Map.Poly.set ~key:se ~data:select_terms
    | _ -> term_map

let qualifiers_of sort terms =
  (* print_endline @@ sprintf "terms:%d" (Set.Poly.length terms);
     Set.Poly.iter terms ~f:(fun t -> print_endline @@ Term.str_of t); *)
  match sort with
  | T_array.SArray _ -> Set.Poly.map ~f:(Formula.mk_atom) @@ Set.Poly.of_list @@ T_bool.mk_eqs @@ List.filter ~f:(Term.is_var) (Set.Poly.to_list terms)
  | _ -> Set.Poly.empty
