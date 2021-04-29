open Core
open Common
open Ast
open Logic
open Util

(** recursion-free CHC solver based on forward propagation *)
(* we assume that CHC is satisfiable and contains no undefined predicate variable *)

let rec solve exi_senv lbs cs =
  let ps = Set.Poly.map cs ~f:(fun c -> match Set.Poly.choose @@ Clause.pos_pvars c with | None -> assert false | Some pvar -> pvar) in
  let ready_to_compute_lb c =
    Set.Poly.for_all ~f:(Map.Poly.mem lbs) @@ Clause.neg_pvars c
  in
  let ps_ready = Set.Poly.filter ps ~f:(fun pvar ->
      Set.Poly.for_all ~f:ready_to_compute_lb @@ Set.Poly.filter cs ~f:(Clause.is_definite pvar)) in

  let cs1, cs2 =
    Set.Poly.partition_tf ~f:(fun c -> Set.Poly.exists ps_ready ~f:(fun p -> Clause.is_definite p c)) cs
  in
  if Set.Poly.is_empty cs1 then
    if Set.Poly.is_empty cs2 then Ok (Problem.Sat lbs)
    else Or_error.error_string "not supported"
  else
    let lbs' =
      let cs1 = ClauseSet.subst exi_senv lbs cs1 in
      cs1
      |> Set.Poly.map ~f:(fun c -> match Set.Poly.choose @@ Clause.pos_pvars c with | None -> assert false | Some pvar -> pvar)
      |> Set.Poly.map ~f:(fun pvar ->
          let env, phi = ClauseSet.pred_of exi_senv cs1 pvar in
          pvar, Term.mk_lambda env phi)
      |> Set.Poly.to_list |> Map.Poly.of_alist_exn
      |> Map.force_merge lbs
    in
    solve exi_senv lbs' cs2
let solve pcsp =
  Problem.to_nnf pcsp
  |> Problem.to_cnf
  |> Problem.clauses_of
  |> Set.Poly.filter ~f:(fun c -> not @@ Clause.is_goal c)
  |> solve (Problem.senv_of pcsp) Map.Poly.empty
