From Coq Require Import String ZArith List.
From cjr Require Import lang.
From cjr.examples Require Import cj_print generic_print.
Import ListNotations.
Local Open Scope string_scope.
From cjr.examples Require list list_rev array array_list hash_map qsort most_frequent.
From cjr.examples Require Import poly_array.
From cjr.collections Require Import copy_lowering.
Definition int (n : Z) : expr := Val (LitV (LitInt n)).
Definition unit_e : expr := Val (LitV LitUnit).

Definition t_int := "Int64".
Definition t_ptr := "CPointer<Int64>".

(** * Layouts *)

Definition cell_s := Decl "Cell" [("x", t_int)].
Definition box_c := Decl "Box" [("value", t_int)].
Definition counter_c := Decl "Counter" [("value", t_int)].
Definition vtable_s := Decl "VTable" [("inc", "(Counter) -> Unit")].
Definition node_c := Decl "Node" [("isCons", "Bool"); ("value", t_int); ("next", "Node")].
Definition array_c := Decl "Array" [("len", t_int); ("data", t_ptr)].
Definition array_list_c :=
  Decl "ArrayList" [("myData", "Array"); ("mySize", t_int); ("myVersion", t_int)].
Definition hash_map_c :=
  Decl "HashMap" [("mySize", t_int); ("tags", "Array"); ("keys", "Array"); ("vals", "Array")].
Definition probe_result_s :=
  Decl "ProbeResult" [("found", "Bool"); ("index", t_int); ("value", t_int)].
Definition int64_opt_c :=
  Decl "Int64Option" [("ok", "Bool"); ("value", t_int)].

(** * Libraries *)

Definition p_list :=
  Prog [node_c] []
    [Fn "nil" None None list.nil_body [] "Node";
     Fn "cons" None (Some "a") list.cons_body [t_int; "Node"] "Node";
     Fn "head" None (Some "n") list.head_body ["Node"] t_int;
     Fn "tail" None (Some "n") list.tail_body ["Node"] "Node";
     Fn "empty" None (Some "n") list.empty_body ["Node"] "Bool"]
    (Let (Some "e") (App (Rec None None list.nil_body) unit_e)
      (Let (Some "l") (App (Rec None (Some "a") list.cons_body) (Struct [] [int 1; Var "e"]))
        (Let (Some "h") (App (Rec None (Some "n") list.head_body) (Var "l"))
          (Let (Some "t") (App (Rec None (Some "n") list.tail_body) (Var "l"))
            (App (Rec None (Some "n") list.empty_body) (Var "t")))))).

(** Standalone reversal library, sharing the list representation and constructors. *)
Definition p_list_rev :=
  Prog [node_c] []
    [Fn "nil" None None list.nil_body [] "Node";
     Fn "cons" None (Some "a") list.cons_body [t_int; "Node"] "Node";
     Fn "head" None (Some "n") list.head_body ["Node"] t_int;
     Fn "tail" None (Some "n") list.tail_body ["Node"] "Node";
     Fn "empty" None (Some "n") list.empty_body ["Node"] "Bool";
     Fn "reverse" None (Some "n") list_rev.rev_body ["Node"] "Node"]
    (Let (Some "e") (App (Rec None None list.nil_body) unit_e)
      (Let (Some "l")
        (App (Rec None (Some "a") list.cons_body) (Struct [] [int 1; Var "e"]))
        (App (Rec None (Some "n") list_rev.rev_body) (Var "l")))).

Definition p_array :=
  Prog [array_c] []
    [Fn "make" None (Some "n") array.make_body [t_int] "Array";
     Fn "length" None (Some "a") array.length_body ["Array"] t_int;
     Fn "get" None (Some "args") array.get_body ["Array"; t_int] t_int;
     Fn "set" None (Some "args") array.set_body ["Array"; t_int; t_int] "Unit"]
    (Let (Some "a") (App (Rec None (Some "n") array.make_body) (int 4))
      (Let None
        (App (Rec None (Some "args") array.set_body) (Struct [] [Var "a"; int 0; int 7]))
        (Let (Some "x") (App (Rec None (Some "args") array.get_body) (Struct [] [Var "a"; int 0]))
          (App (Rec None (Some "a") array.length_body) (Var "a"))))).

Definition al := Some "ArrayList".
Definition hm := Some "HashMap".

Definition p_hash_map :=
  Prog [array_c; hash_map_c] [int64_opt_c; probe_result_s]
    [Fn "make" None (Some "n") array.make_body [t_int] "Array";
     Fn "length" None (Some "a") array.length_body ["Array"] t_int;
     Fn "arrayGet" None (Some "args") array.get_body ["Array"; t_int] t_int;
     Fn "arraySet" None (Some "args") array.set_body ["Array"; t_int; t_int] "Unit";
     Fn "residue" None (Some "args") hash_map.residue_body [t_int; t_int] t_int;
     Fn "hashBucket" None (Some "args") hash_map.bucket_body [t_int; t_int] t_int;
     Fn "scan" None (Some "args") hash_map.scan_body
       [t_int; t_int; t_int; t_int; "Array"; "Array"; "Array"; t_int; t_int] "ProbeResult";
     Fn "bufferProbe" None (Some "args") hash_map.buffer_probe_body
       ["Array"; "Array"; "Array"; t_int; t_int] "ProbeResult";
     Fn "lookupBuffer" None (Some "args") hash_map.lookup_buffer_body
       ["Array"; "Array"; "Array"; t_int; t_int; t_int] "Int64Option";
     Fn "lookup" hm (Some "args") hash_map.lookup_for_body [t_int] "Int64Option";
     Fn "put" None (Some "args") hash_map.put_body
       ["Array"; "Array"; "Array"; t_int; t_int; t_int] "Unit";
     Fn "rehash" None (Some "args") hash_map.rehash_body
       [t_int; t_int; "Array"; "Array"; "Array"; t_int; "Array"; "Array"; "Array"] "Unit";
     Fn "probe" hm (Some "args") hash_map.probe_for_body [t_int] "ProbeResult";
     Fn "addRoom" hm (Some "args") hash_map.add_room_body [t_int; t_int; "Bool"] "Unit";
     Fn "initHashMap" None None hash_map.init_body [] "HashMap";
     Fn "size" hm (Some "m") hash_map.size_body [] t_int;
     Fn "capacity" hm (Some "m") hash_map.capacity_body [] t_int;
     Fn "isEmpty" hm (Some "m") hash_map.is_empty_body [] "Bool";
     Fn "contains" hm (Some "args") hash_map.contains_body [t_int] "Bool";
     Fn "get" hm (Some "args") hash_map.get_body [t_int] "Int64Option";
     Fn "add" hm (Some "args") hash_map.add_body [t_int; t_int] "Unit";
     Fn "remove" hm (Some "args") hash_map.remove_body [t_int] t_int;
     Fn "grow" hm (Some "args") hash_map.grow_body [t_int] "Unit"]
    (Let (Some "m") (App (Rec None None hash_map.init_body) unit_e)
      (Let None
        (App (Rec None (Some "args") hash_map.add_body) (Struct [] [Var "m"; int 1; int 2]))
        (Let (Some "r")
          (App (Rec None (Some "args") hash_map.get_body) (Struct [] [Var "m"; int 1]))
          (App (Rec None (Some "m") hash_map.size_body) (Var "m"))))).

Definition p_array_list :=
  Prog [array_c; array_list_c] []
    [Fn "initArrayList" None None array_list.init_body [] "ArrayList";
     Fn "size" al (Some "a") array_list.size_body [] t_int;
     Fn "capacity" al (Some "a") array_list.capacity_body [] t_int;
     Fn "version" al (Some "a") array_list.version_body [] t_int;
     Fn "isEmpty" al (Some "a") array_list.is_empty_body [] "Bool";
     Fn "get" al (Some "args") array_list.al_get_body [t_int] t_int;
     Fn "set" al (Some "args") array_list.al_set_body [t_int; t_int] "Unit";
     Fn "grow" al (Some "args") array_list.grow_body [t_int] "Unit";
     Fn "add" al (Some "args") array_list.add_body [t_int] "Unit";
     Fn "remove" al (Some "args") array_list.remove_body [t_int] t_int]
    (Let (Some "a") (App (Rec None None array_list.init_body) unit_e)
      (Let None
        (App (Rec None (Some "args") array_list.add_body) (Struct [] [Var "a"; int 1]))
        (Let None
          (App (Rec None (Some "args") array_list.add_body) (Struct [] [Var "a"; int 2]))
          (Let (Some "r")
            (App (Rec None (Some "args") array_list.remove_body) (Struct [] [Var "a"; int 0]))
            (App (Rec None (Some "a") array_list.size_body) (Var "a")))))).

(** * Quicksort

One algorithm, printed twice. The array file calls the free functions
[length], [get], and [set]. The array-list file calls the methods
[size], [get], and [set]. [add] is included so a program can fill the
list, and [add] calls [grow]. *)

Definition array_swap := qsort.swap_body array.get_body array.set_body.
Definition array_partition :=
  qsort.partition_body array.get_body array.set_body.
Definition array_qsort := qsort.qsort_body array.get_body array.set_body.
Definition array_sort :=
  qsort.sort_body array.length_body array.get_body array.set_body.

Definition p_qsort_array :=
  Prog [array_c] []
    [Fn "make" None (Some "n") array.make_body [t_int] "Array";
     Fn "length" None (Some "a") array.length_body ["Array"] t_int;
     Fn "get" None (Some "args") array.get_body ["Array"; t_int] t_int;
     Fn "set" None (Some "args") array.set_body ["Array"; t_int; t_int] "Unit";
     Fn "swap" None (Some "args") array_swap ["Array"; t_int; t_int] "Unit";
     Fn "partition" None (Some "args") array_partition
       ["Array"; t_int; t_int] t_int;
     Fn "qsort" None (Some "args") array_qsort ["Array"; t_int; t_int] "Unit";
     Fn "sort" None (Some "a") array_sort ["Array"] "Unit"]
    (Let (Some "a") (App (Rec None (Some "n") array.make_body) (int 3))
      (Let None
        (App (Rec None (Some "args") array.set_body)
          (Struct [] [Var "a"; int 0; int 3]))
        (Let None
          (App (Rec None (Some "args") array.set_body)
            (Struct [] [Var "a"; int 1; int 1]))
          (Let None
            (App (Rec None (Some "args") array.set_body)
              (Struct [] [Var "a"; int 2; int 2]))
            (App (Rec None (Some "a") array_sort) (Var "a")))))).

Definition list_swap :=
  qsort.swap_body array_list.al_get_body array_list.al_set_body.
Definition list_partition :=
  qsort.partition_body array_list.al_get_body array_list.al_set_body.
Definition list_qsort :=
  qsort.qsort_body array_list.al_get_body array_list.al_set_body.
Definition list_sort :=
  qsort.sort_body array_list.size_body array_list.al_get_body
    array_list.al_set_body.

Definition p_qsort_array_list :=
  Prog [array_c; array_list_c] []
    [Fn "initArrayList" None None array_list.init_body [] "ArrayList";
     Fn "size" al (Some "a") array_list.size_body [] t_int;
     Fn "capacity" al (Some "a") array_list.capacity_body [] t_int;
     Fn "version" al (Some "a") array_list.version_body [] t_int;
     Fn "get" al (Some "args") array_list.al_get_body [t_int] t_int;
     Fn "set" al (Some "args") array_list.al_set_body [t_int; t_int] "Unit";
     Fn "grow" al (Some "args") array_list.grow_body [t_int] "Unit";
     Fn "add" al (Some "args") array_list.add_body [t_int] "Unit";
     Fn "swap" None (Some "args") list_swap ["ArrayList"; t_int; t_int] "Unit";
     Fn "partition" None (Some "args") list_partition
       ["ArrayList"; t_int; t_int] t_int;
     Fn "qsort" None (Some "args") list_qsort
       ["ArrayList"; t_int; t_int] "Unit";
     Fn "sort" None (Some "a") list_sort ["ArrayList"] "Unit"]
    (Let (Some "a") (App (Rec None None array_list.init_body) unit_e)
      (Let None
        (App (Rec None (Some "args") array_list.add_body)
          (Struct [] [Var "a"; int 3]))
        (Let None
          (App (Rec None (Some "args") array_list.add_body)
            (Struct [] [Var "a"; int 1]))
          (Let None
            (App (Rec None (Some "args") array_list.add_body)
              (Struct [] [Var "a"; int 2]))
            (App (Rec None (Some "a") list_sort) (Var "a")))))).

(** Most-frequent: printed from the parallel-array CJR terms. *)
Definition p_most_frequent :=
  Prog [array_c] [int64_opt_c]
    [Fn "make" None (Some "n") array.make_body [t_int] "Array";
     Fn "length" None (Some "a") array.length_body ["Array"] t_int;
     Fn "get" None (Some "args") array.get_body ["Array"; t_int] t_int;
     Fn "set" None (Some "args") array.set_body ["Array"; t_int; t_int] "Unit";
     Fn "pairSwap" None (Some "args") most_frequent.mf_swap_body
       ["Array"; "Array"; t_int; t_int] "Unit";
     Fn "pairPartition" None (Some "args") most_frequent.mf_partition_body
       ["Array"; "Array"; t_int; t_int] t_int;
     Fn "pairQsort" None (Some "args") most_frequent.mf_qsort_body
       ["Array"; "Array"; t_int; t_int] "Unit";
     Fn "mostFrequent" None (Some "input") most_frequent.mf_body ["Array"] "Int64Option"]
    (Let (Some "input") (App (Rec None (Some "n") array.make_body) (int 1))
      (Let None
        (App (Rec None (Some "args") array.set_body)
          (Struct [] [Var "input"; int 0; int 42]))
        (App (Rec None (Some "input") most_frequent.mf_body) (Var "input")))).

Definition cj_files : list (string * prog) :=
[("list",p_list); ("list_rev",p_list_rev); ("array",p_array); ("array_list",p_array_list);
 ("hash_map",p_hash_map); ("qsort_array",p_qsort_array); ("qsort_array_list",p_qsort_array_list); ("most_frequent",p_most_frequent)].
Definition cj_bundle : string := cat_all (map (fun '(n,p) => "@@FILE " ++ n ++ nl ++ print_prog_with collection_copy_rules p) cj_files) ++ "@@FILE poly_array" ++ nl ++ generic_source poly_program.
