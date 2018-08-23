module Compiler where

  open import Data.Nat.Base renaming (_+_ to _ℕ+_)
  open import NatProofs
  open import Agda.Builtin.Equality


------------------------------
-- Expression-tree language --
------------------------------

  -- definition of Expression-tree Language (ETL)
  data Exp : Set where  
    ↓    : ℕ → Exp
    _+_  : Exp → Exp → Exp


  -- function: execute ETL program
  exe : Exp → ℕ
  exe (↓ n)    = n
  exe (n + m)  = exe n ℕ+ exe m


--------------------
-- Stack language --
--------------------

  -- definition of Stack, indexed by a natural number representing stack height
  infixr 20 _~_
  data Stack : ℕ → Set where
    #   : Stack 0
    _~_ : ∀ {n} → ℕ → Stack n → Stack (suc n)

  -- definition of expressions that can be used to manipulate stack, indexed by 2 natural
  -- numbers representing stack height before and after expression execution respectively.
  data SExp : ℕ → ℕ → Set where
    push : ∀ {n} → ℕ → SExp n (suc n)
    add  : ∀ {n} → SExp (suc (suc n)) (suc n)

  -- definition of list of SExp, i.e. a stack program. indexed by two numbers representing
  -- stack height before and after program execution respectively.
  infixr 20 _::_
  data SEList : ℕ → ℕ → Set where
    []    : ∀ {x} → SEList x x
    _::_  : ∀ {x y z} → SExp x y → SEList y z → SEList x z

  -- function: execute Stack Machine Language (SML) program
  exs : ∀ {x y} → SEList x y → Stack x → Stack y
  exs [] s = s
  exs (x :: xs) s with x | s
  ... | push n | _             = exs xs (n ~ s)
  ... | add    | s1 ~ s2 ~ ss  = exs xs ((s1 ℕ+ s2) ~ ss) 


--------------
-- Compiler --
--------------

  -- function: join two SML programs
  infixl 20 _++_
  _++_ : ∀ {x y z} → SEList x y → SEList y z → SEList x z
  [] ++ l          = l                                        
  ((x :: xs) ++ l)   = (x :: (xs ++ l))

  -- function: compile ETL to SML
  compile : ∀ {n} → Exp → SEList n (suc n)
  compile (↓ n)     = (push n) :: []
  compile (e1 + e2) = (compile e1) ++ (compile e2) ++ (add :: [])


------------------
-- Verification --
------------------

  -- proof: equality symmetry
  sym : {A : Set} {a b : A} → a ≡ b → b ≡ a
  sym refl = refl

  -- proof: distributive(?) property of exs and _++_
  ++-ex : ∀ {x y z}(s : Stack x)(a : SEList x y)(b : SEList y z) → exs (a ++ b) s ≡ exs b (exs a s)
  ++-ex _ [] b = refl
  ++-ex s (x :: xs) b with x | s
  ... | push n | ss = ++-ex (n ~ ss) xs b
  ... | add    | (s1 ~ s2 ~ ss) = ++-ex ((s1 ℕ+ s2) ~ ss) xs b
  
  -- verification of compiler
  verify : ∀ {n} (exp : Exp)(xs : Stack n) → (exe exp) ~ xs ≡ exs (compile exp) xs
  verify (↓ n) _ = refl
  verify (exp₁ + exp₂) xs rewrite ++-ex xs ((compile exp₁) ++ (compile exp₂)) (add :: []) | ++-ex xs (compile exp₁) (compile exp₂) | sym (verify exp₁ xs) | sym (verify exp₂ (exe exp₁ ~ xs)) | +comm (exe exp₁) (exe exp₂) = refl
