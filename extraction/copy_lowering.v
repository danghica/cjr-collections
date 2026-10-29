(** Exact, collection-owned policy for the guarded memmove lowering. *)
From Coq Require Import List.
From cjr.examples Require Import cj_print array_list.
Import ListNotations.
Definition collection_copy_rules : copy_rules :=
  CopyRules [array_list.grow_body; array_list.remove_body] (Some array_list.copy_vars).
Example bulk_copy_grow_enabled : bulk_copy_method collection_copy_rules array_list.grow_body = true.
Proof. vm_compute. reflexivity. Qed.
Example bulk_copy_remove_enabled : bulk_copy_method collection_copy_rules array_list.remove_body = true.
Proof. vm_compute. reflexivity. Qed.
Example bulk_copy_arbitrary_loop_disabled : bulk_copy_method collection_copy_rules array_list.copy_vars = false.
Proof. vm_compute. reflexivity. Qed.
Example bulk_copy_get_disabled : bulk_copy_method collection_copy_rules array_list.al_get_body = false.
Proof. vm_compute. reflexivity. Qed.
