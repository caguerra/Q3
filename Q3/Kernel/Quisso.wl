(* -*- mode: math; -*- *)

BeginPackage["Q3`"]

`Quisso`$Version = StringJoin[
  $Input, " v",
  StringSplit["$Revision: 3.80 $"][[2]], " (",
  StringSplit["$Date: 2021-09-04 19:36:31+09 $"][[2]], ") ",
  "Mahn-Soo Choi"
 ];

{ Qubit, QubitQ, Qubits };

{ PauliForm };

{ DensityMatrix, DensityOperator };

{ QuissoReduced, ReducedDensityMatrix };

{ QuissoCoefficientTensor, QuissoAssemble };

{ QuissoAdd, QuissoAddZ };

{ Phase, Rotation, EulerRotation };

{ ControlledU, CZ, CNOT, SWAP, Toffoli, Fredkin,
  Projector, Measurement, Readout };

{ Oracle, VerifyOracle };

{ QuantumFourierTransform };

{ ProductState, BellState, GraphState, DickeState, RandomState };

{ QuantumCircuit, QuissoIn, QuissoOut,
  QuantumCircuitTrim };

(* Qudit *)

{ Qudit, QuditQ, Qudits };

{ TheQuditKet };

(* Obsolete Symbols *)

{ QuissoPhase, QuissoControlledU,
  QuissoRotation, QuissoEulerRotation,
  QuissoCZ, QuissoCNOT, QuissoSWAP, QuissoToffoli, QuissoFredkin,
  QuissoOracle }; (* obsolete *)

{ QuissoFactor }; (* OBSOLETE *)

{ QuissoExpression, QuissoExpressionRL }; (* obsolete *)

{ QuissoCircuit, QuissoExpand }; (* OBSOLETE *)

{ QuditExpression }; (* OBSOLETE *)

{ Dirac }; (* OBSOLETE *)

Begin["`Private`"]

$symb = Unprotect[CircleTimes, Dagger, Ket, Bra, Missing]

Qubit::usage = "Qubit denotes a quantum two-level system or \"quantum bit\".\nLet[Qubit, S, T, ...] or Let[Qubit, {S, T,...}] declares that the symbols S, T, ... are dedicated to represent qubits and quantum gates operating on them. For example, S[j,..., None] represents the qubit located at the physical site specified by the indices j, .... On the other hand, S[j, ..., k] represents the quantum gate operating on the qubit S[j,..., None].\nS[..., 0] represents the identity operator.\nS[..., 1], S[..., 2] and S[..., 3] means the Pauli-X, Pauli-Y and Pauli-Z gates, respectively.\nS[..., 4] and S[..., 5] represent the raising and lowering operators, respectively.\nS[..., 6], S[..., 7], S[..., 8] represent the Hadamard, Quadrant (Pi/4) and Octant (Pi/8) gate, resepctively.\nS[..., 10] represents the projector into Ket[0].\nS[..., 11] represents the projector into Ket[1].\nS[..., (Raise|Lower|Hadamard|Quadrant|Octant)] are equivalent to S[..., (4|5|6|7|8)], respectively, but expanded immediately in terms of S[..., 1] (Pauli-X), S[..., 2] (Y), and S[..., 3] (Z).\nS[..., None] represents the qubit."

Qubit /:
Let[Qubit, {ls__Symbol}, opts___?OptionQ] := (
  Let[NonCommutative, {ls}];
  Scan[setQubit, {ls}];
 )

setQubit[x_Symbol] := (
  Kind[x] ^= Qubit;
  Kind[x[___]] ^= Qubit;
  
  Dimension[x] ^= 2;
  Dimension[x[___]] ^= 2;

  LogicalValues[x] ^= {0, 1};
  LogicalValues[x[___]] ^= {0, 1};

  QubitQ[x] ^= True;
  QubitQ[x[___]] ^= True;

  x/: Dagger[ x[j___, k:(0|1|2|3|6|10|11)] ] := x[j, k];
  x/: Dagger[ x[j___, 4] ] := x[j,5];
  x/: Dagger[ x[j___, 5] ] := x[j,4];

  x/: Inverse[ x[j___, k:(0|1|2|3|6)] ] := x[j, k];
  x/: Inverse[ x[j___, 7] ] := Dagger @ x[j, 7];
  x/: Inverse[ x[j___, 8] ] := Dagger @ x[j, 8];

  (* for time reversal *)
  x/: Conjugate[ x[j___, k:(0|1|3|4|5|6)] ] := x[j, k];
  x/: Conjugate[ x[j___, 2] ] := -x[j, 2];
  x/: Conjugate[ x[j___, 7] ] := Dagger @ x[j, 7];
  x/: Conjugate[ x[j___, 8] ] := Dagger @ x[j, 8];

  x /: Power[x, n_Integer] := MultiplyPower[x, n];
  x /: Power[x[j___], n_Integer] := MultiplyPower[x[j], n];

  x[j___, Raise] := (x[j,1] + I x[j,2]) / 2;
  x[j___, Lower] := (x[j,1] - I x[j,2]) / 2;
  
  x[j___, Hadamard] := (x[j,1] + x[j,3]) / Sqrt[2];
  x[j___, Quadrant] := (1+I)/2 + x[j,3] (1-I)/2;
  x[j___, Octant]   := (1+Exp[I Pi/4])/2 + x[j,3] (1-Exp[I Pi/4])/2;

  (* x[j___, 10] := (1 + x[j,3]) / 2; *)
  (* x[j___, 11] := (1 - x[j,3]) / 2; *)
  (* NOTE: It interferes, say, with Ket[] encountered with short-cut inputs *)

  x[j___, 0 -> 0] := x[j, 10];
  x[j___, 1 -> 1] := x[j, 11];
  x[j___, 1 -> 0] := x[j, 4];
  x[j___, 0 -> 1] := x[j, 5];
  
  x[j___, All]  := Flatten @ x[j, {1,2,3}];

  x[j___, Full] := Flatten @ x[j, {0,1,2,3}];
  
  x[j___, Null] := x[j, None];
  
  x[j___, None, k_] := x[j, k];
  (* In particular, x[j,None,None] = x[j,None]. *)
  
  Format[ x[j___, None] ] := SpeciesBox[x, {j}, {}];
  
  Format[ x[j___, 0] ] := SpeciesBox[x, {j}, {0}];
  Format[ x[j___, 1] ] := SpeciesBox[x, {j}, {"x"}];
  Format[ x[j___, 2] ] := SpeciesBox[x, {j}, {"y"}];
  Format[ x[j___, 3] ] := SpeciesBox[x, {j}, {"z"}];
  Format[ x[j___, 4] ] := SpeciesBox[x, {j}, {"+"}];
  Format[ x[j___, 5] ] := SpeciesBox[x, {j}, {"-"}];
  Format[ x[j___, 6] ] := SpeciesBox[x, {j}, {"H"}];
  Format[ x[j___, 7] ] := SpeciesBox[x, {j}, {"S"}];
  Format[ x[j___, 8] ] := SpeciesBox[x, {j}, {"T"}];
  
  Format[ x[j___, 10] ] := Subscript[
    DisplayForm @ RowBox @ {"(", Ket[0], Bra[0], ")"},
    x[j, None]
   ];
  Format[ x[j___, 11] ] := Subscript[
    DisplayForm @ RowBox @ {"(", Ket[1], Bra[1], ")"},
    x[j, None]
   ];
 )

Missing["KeyAbsent", _Symbol?QubitQ[___, None]] := 0


(* Override the default definition of Format[Dagger[...]]
   NOTE: This is potentially dangerous because Fock also overides it. *)

Format[ HoldPattern @ Dagger[ c_Symbol?SpeciesQ[j___] ] ] =. ;

Format[ HoldPattern @ Dagger[ c_Symbol?QubitQ[j___, 7] ] ] :=
  DisplayForm @ SpeciesBox[c, {j}, {"S\[Dagger]"}] /; $FormatSpecies

Format[ HoldPattern @ Dagger[ c_Symbol?QubitQ[j___, 8] ] ] :=
  DisplayForm @ SpeciesBox[c, {j}, {"T\[Dagger]"}] /; $FormatSpecies

Format[ HoldPattern @ Dagger[ c_Symbol?SpeciesQ[j___] ] ] := 
  DisplayForm @ SpeciesBox[c, {j}, {"\[Dagger]"} ] /; $FormatSpecies

Format[ HoldPattern @ Dagger[ c_Symbol?SpeciesQ ] ] := 
  DisplayForm @ SpeciesBox[c, {}, {"\[Dagger]"} ] /; $FormatSpecies


QubitQ::usage = "QubitQ[S] or QubitQ[S[...]] returns True if S is declared as a Qubit through Let."

QubitQ[_] = False


Qubits::usage = "Qubits[expr] gives the list of all qubits (quantum bits) appearing in expr."

Qubits[ expr_ ] := FlavorNone @ Union @ Map[Most] @
  Cases[ { Normal[expr, Association] }, _?QubitQ, Infinity ]
(* NOTE 1: The outermost { } is necessary around expr; otherwise,
   Qubits[S[1,2]] does not give the trivial result. *)
(* NOTE 2: Normal[{expr}, Association] is not enough as nested Association[]s
   are not converted properly. This is due to the HoldAllComplete Attribute of
   Association. *)


(**** <Multiply> ****)

(* Speical Rules: Involving identity *)

HoldPattern @ Multiply[a___, _?QubitQ[___, 0], b___] := Multiply[a, b]

(* Multiply operators on Ket[] *)

HoldPattern @
  Multiply[ pre___, a_?QubitQ[j___,4], Ket[b_Association], post___ ] :=
  0 /; b @ a[j, None] == 0

HoldPattern @
  Multiply[ pre___, a_?QubitQ[j___,4], Ket[b_Association], post___ ] :=
  Multiply[
    pre,
    Ket @ KeyDrop[b, a[j, None]],
    post
   ] /; b @ a[j, None] == 1

HoldPattern @
  Multiply[ pre___, a_?QubitQ[j___,5], Ket[b_Association], post___ ] :=
  0 /; b @ a[j, None] == 1

HoldPattern @
  Multiply[ pre___, a_?QubitQ[j___,5], Ket[b_Association], post___ ] :=
  Multiply[
    pre,
    Ket[b][a[j, None] -> 1],
    post
   ] /; b @ a[j, None] == 0

HoldPattern @
  Multiply[ pre___, a_?QubitQ[j___,1], Ket[b_Association], post___ ] :=
  With[
    { m = Mod[ 1 + b[ a[j,None] ], 2 ] },
    Multiply[
      pre,
      Ket @ KeySort @ KetTrim @ Append[ b, a[j,None]->m ],
      post
     ]
   ]

HoldPattern @
  Multiply[ pre___, a_?QubitQ[j___,2], Ket[b_Association], post___ ] :=
  With[
    { m = Mod[ 1 + b[ a[j,None] ], 2 ] },
    (2 m - 1) I Multiply[
      pre,
      Ket @ KeySort @ KetTrim @ Append[ b, a[j,None]->m ],
      post
     ]
   ]

HoldPattern @
  Multiply[ x___, a_?QubitQ[j___,3], Ket[b_Association], y___ ] :=
  (1 - 2 b[a[j,None]]) *
  Multiply[x, Ket @ KetTrim @ b, y]

(*
HoldPattern @ Multiply[ x___, a_?QubitQ[j___,4], Ket[b_Association], y___ ] :=
  Multiply[x, a[j,Raise], Ket[b], y]

HoldPattern @ Multiply[ x___, a_?QubitQ[j___,5], Ket[b_Association], y___ ] :=
  Multiply[x, a[j,Lower], Ket[b], y]
 *)

HoldPattern @ Multiply[ x___, a_?QubitQ[j___,6], Ket[b_Association], y___ ] :=
  Multiply[x, a[j,Hadamard], Ket[b], y]

HoldPattern @ Multiply[ x___, a_?QubitQ[j___,7], Ket[b_Association], y___ ] :=
  Multiply[x, a[j,Quadrant], Ket[b], y]

HoldPattern @ Multiply[ x___, a_?QubitQ[j___,8], Ket[b_Association], y___ ] :=
  Multiply[x, a[j,Octant], Ket[b], y]


HoldPattern @
  Multiply[ pre___, a_?QubitQ[j___,10], Ket[b_Association], post___ ] :=
  Multiply[pre, Ket[b], post] /; b @ a[j, None] == 0

HoldPattern @
  Multiply[ pre___, a_?QubitQ[j___,10], Ket[b_Association], post___ ] :=
  0 /; b @ a[j, None] == 1

HoldPattern @
  Multiply[ pre___, a_?QubitQ[j___,11], Ket[b_Association], post___ ] :=
  Multiply[pre, Ket[b], post] /; b @ a[j, None] == 1

HoldPattern @
  Multiply[ pre___, a_?QubitQ[j___,11], Ket[b_Association], post___ ] :=
  0 /; b @ a[j, None] == 0

(* Gates on Bra *)

HoldPattern @ Multiply[ x___, Bra[v_Association], G_?QubitQ, y___ ] :=
  Multiply[ x, Dagger[Dagger[G]**Ket[v]], y ]

HoldPattern @ Multiply[ x___, Bra[v_Association, s_List], G_?QubitQ, y___ ] :=
  Multiply[ x, Dagger[Dagger[G]**Ket[v,s]], y ]


(* Special rules for Pauli matrices *)
 
HoldPattern @ Multiply[ pre___,
  x_Symbol?QubitQ[j___,k:(1|2|3|6)], x_Symbol?QubitQ[j___,k:(1|2|3|6)],
  post___ ] := Multiply[pre, post]

HoldPattern @ Multiply[ ___,
  x_Symbol?QubitQ[j___,k:(4|5)], x_Symbol?QubitQ[j___,k:(4|5)],
  ___ ] := 0

HoldPattern @ Multiply[ pre___,
  x_Symbol?QubitQ[j___,7], x_Symbol?QubitQ[j___,7], post___ ] :=
  Multiply[pre, x[j,3], post]

HoldPattern @ Multiply[ pre___,
  x_Symbol?QubitQ[j___,8], x_Symbol?QubitQ[j___,8], post___ ] :=
  Multiply[pre, x[j,7], post]


HoldPattern @ Multiply[ pre___,
  x_Symbol?QubitQ[j___,1], x_Symbol?QubitQ[j___,2], post___ ] :=
  Multiply[pre, I x[j,3], post]

HoldPattern @ Multiply[ pre___,
  x_Symbol?QubitQ[j___,2], x_Symbol?QubitQ[j___,3], post___ ] :=
  Multiply[pre, I x[j,1], post]

HoldPattern @ Multiply[ pre___,
  x_Symbol?QubitQ[j___,3], x_Symbol?QubitQ[j___,1], post___ ] :=
  Multiply[pre, I x[j,2], post]

HoldPattern @ Multiply[ pre___,
  x_Symbol?QubitQ[j___,2], x_Symbol?QubitQ[j___,1], post___ ] :=
  Multiply[pre, -I x[j,3], post]

HoldPattern @ Multiply[ pre___,
  x_Symbol?QubitQ[j___,3], x_Symbol?QubitQ[j___,2], post___ ] :=
  Multiply[pre, -I x[j,1], post]

HoldPattern @ Multiply[ pre___,
  x_Symbol?QubitQ[j___,1], x_Symbol?QubitQ[j___,3], post___ ] :=
  Multiply[pre, -I x[j,2], post]
(* Again, the last three definitions can be deduced from the commutation
   relations below, but explicit definition makes the evaluation much
   faster. *)


HoldPattern @ Multiply[ pre___,
  x_Symbol?QubitQ[j___,1], x_Symbol?QubitQ[j___,4], post___ ] :=
  Multiply[pre, 1/2 - x[j,3]/2, post]

HoldPattern @ Multiply[ pre___,
  x_Symbol?QubitQ[j___,4], x_Symbol?QubitQ[j___,1], post___ ] :=
  Multiply[pre, 1/2 + x[j,3]/2, post]


HoldPattern @ Multiply[ pre___,
  x_Symbol?QubitQ[j___,1], x_Symbol?QubitQ[j___,5], post___ ] :=
  Multiply[pre, 1/2 + x[j,3]/2, post]

HoldPattern @ Multiply[ pre___,
  x_Symbol?QubitQ[j___,5], x_Symbol?QubitQ[j___,1], post___ ] :=
  Multiply[pre, 1/2 - x[j,3]/2, post]


HoldPattern @ Multiply[ pre___,
  x_Symbol?QubitQ[j___,2], x_Symbol?QubitQ[j___,4], post___ ] :=
  Multiply[pre, I/2 - x[j,3]*I/2, post]

HoldPattern @ Multiply[ pre___,
  x_Symbol?QubitQ[j___,4], x_Symbol?QubitQ[j___,2], post___ ] :=
  Multiply[pre, I/2 + x[j,3]*I/2, post]


HoldPattern @ Multiply[ pre___,
  x_Symbol?QubitQ[j___,2], x_Symbol?QubitQ[j___,5], post___ ] :=
  Multiply[pre, -I/2 - x[j,3]*I/2, post]

HoldPattern @ Multiply[ pre___,
  x_Symbol?QubitQ[j___,5], x_Symbol?QubitQ[j___,2], post___ ] :=
  Multiply[pre, -I/2 + x[j,3]*I/2, post]


HoldPattern @ Multiply[ pre___,
  x_Symbol?QubitQ[j___,3], x_Symbol?QubitQ[j___,4], post___ ] :=
  Multiply[pre, +x[j,4], post]

HoldPattern @ Multiply[ pre___,
  x_Symbol?QubitQ[j___,4], x_Symbol?QubitQ[j___,3], post___ ] :=
  Multiply[pre, -x[j,4], post]


HoldPattern @ Multiply[ pre___,
  x_Symbol?QubitQ[j___,3], x_Symbol?QubitQ[j___,5], post___ ] :=
  Multiply[pre, -x[j,5], post]

HoldPattern @ Multiply[ pre___,
  x_Symbol?QubitQ[j___,5], x_Symbol?QubitQ[j___,3], post___ ] :=
  Multiply[pre, +x[j,5], post]


HoldPattern @ Multiply[ pre___,
  x_Symbol?QubitQ[j___,4], x_Symbol?QubitQ[j___,5], post___ ] :=
  Multiply[pre, 1/2 + x[j,3]/2, post]

HoldPattern @ Multiply[ pre___,
  x_Symbol?QubitQ[j___,5], x_Symbol?QubitQ[j___,4], post___ ] :=
  Multiply[pre, 1/2 - x[j,3]/2, post]


(* Hadamard, Quadrant, Octant, Projectors *)

HoldPattern @ Multiply[pre___, x_Symbol?QubitQ[j___,6], post___] :=
  Multiply[pre, x[j,Hadamard], post]

HoldPattern @ Multiply[pre___, x_Symbol?QubitQ[j___,7], post___] :=
  Multiply[pre, x[j,Quadrant], post]

HoldPattern @ Multiply[pre___, x_Symbol?QubitQ[j___,8], post___] :=
  Multiply[pre, x[j,Octant], post]

HoldPattern @ Multiply[pre___, x_Symbol?QubitQ[j___,10], post___] :=
  Multiply[pre, (1 + x[j,3])/2, post]

HoldPattern @ Multiply[pre___, x_Symbol?QubitQ[j___,11], post___] :=
  Multiply[pre, (1 - x[j,3])/2, post]


(* General Rules *)

HoldPattern @ Multiply[pre___, x1_?QubitQ, x2_?QubitQ, post___] :=
  Multiply[pre, x2, x1, post] /;
  Not @ OrderedQ @ {x1, x2}

(**** </Multiply> ****)


(* MultiplyDegree for operators *)
MultiplyDegree[_?QubitQ] = 1


(* Base: See Cauchy *)

Base[ S_?QubitQ[j___, _] ] := S[j]
(* For Qubits, the final Flavor index is special. *)


(* FlavorNone: See Cauchy *)

FlavorNone[S_?QubitQ] := S[None]

FlavorNone[S_?QubitQ -> m_] := S[None] -> m


(* FlavorMute: See Cauchy *)

FlavorMute[S_Symbol?QubitQ] := S[None]

FlavorMute[S_Symbol?QubitQ[j___, _]] := S[j, None]

FlavorMute[S_Symbol?QubitQ[j___, _] -> m_] := S[j, None] -> m


Once[
  $GarnerTests = Union @ Join[$GarnerTests, {QubitQ}];
 ]

Once[
  $RaiseLowerRules = Join[ $RaiseLowerRules,
    { S_?QubitQ[j___,1] :> (S[j,4] + S[j,5]),
      S_?QubitQ[j___,2] :> (S[j,4] - S[j,5]) / I
     }
   ]
 ]


QuissoExpand::usage = "QuissoExpand[expr] expands the expression expr revealing the explicit forms of various operator or state-vector expressions."

QuissoExpand[expr_] := (
  Message[Q3`Q3General::obsolete, QuissoExpand, Elaborate];
  Elaborate[expr]
 )


Once[
  $ElaborationHeads = Join[ $ElaborationHeads,
    { QuantumCircuit, QuantumFourierTransform,
      ControlledU, CZ, CNOT, SWAP, Toffoli, Fredkin, Oracle,
      Phase, Rotation, EulerRotation,
      Projector, ProductState
     }
   ];
  
  $ElaborationRules = Join[ $ElaborationRules,
    { G_?QubitQ[j___, 0] -> 1,
      G_?QubitQ[j___, 4] -> G[j, Raise],
      G_?QubitQ[j___, 5] -> G[j, Lower],
      G_?QubitQ[j___, 6] -> G[j, Hadamard],
      G_?QubitQ[j___, 7] -> G[j, Quadrant],
      G_?QubitQ[j___, 8] -> G[j, Octant],
      G_?QubitQ[j___, 10] -> (1 + G[j,3]) / 2,
      G_?QubitQ[j___, 11] -> (1 - G[j,3]) / 2,
      OTimes -> DefaultForm @* CircleTimes,
      OSlash -> DefaultForm @* CircleTimes
     }
   ];
 ]


ProductState::usage = "ProductState[<|...|>] is similar to Ket[...] but reserved only for product states. ProductState[<|..., S -> {a, b}, ...|>] represents the qubit S is in a linear combination of a Ket[0] + b Ket[1]."

Format[ ProductState[Association[]] ] := Ket[Any]

Format[ ProductState[assoc_Association, ___] ] :=
  CircleTimes @@ KeyValueMap[
    DisplayForm @ Subscript[RowBox @ {"(", {Ket[0], Ket[1]}.#2, ")"}, #1]&,
    assoc
   ]

(* LogicalForm[...] *)

ProductState /:
HoldPattern @ LogicalForm[ ProductState[a_Association], gg_List ] :=
  Module[
    { ss = Union[Keys @ a, FlavorNone @ gg] },
    Block[
      { Missing },
      Missing["KeyAbsent", _Symbol?QubitQ[___, None]] := {1, 0};
      ProductState @ Association @ Thread[ ss -> Lookup[a, ss] ]
     ]
   ]

(* Elaborate[...] *)

ProductState /:
HoldPattern @ Elaborate[ ProductState[a_Association, ___] ] := Garner[
  CircleTimes @@ KeyValueMap[ExpressionFor[#2, #1]&, a]
 ]

(* ProductState in Multiply[...] *)

ProductState /:
NonCommutativeQ[ ProductState[___] ] = True

ProductState /:
Kind[ ProductState[___] ] = Ket

ProductState /:
MultiplyGenus[ ProductState[___] ] = "Ket"

HoldPattern @
  Multiply[ pre___, vec:ProductState[_Association, ___], post___ ] :=
  Garner @ Multiply[pre, Elaborate[vec], post]

(* input specifications *)

ProductState[] = ProductState[Association[]]

ProductState[spec__Rule] :=
  Fold[ ProductState, ProductState[<||>], {spec} ]

ProductState[v:ProductState[_Association, ___], spec_Rule, more__Rule] :=
  Fold[ ProductState, v, {spec} ]

ProductState[ v:ProductState[_Association, ___], rule:(_String -> _) ] :=
  Append[v, rule]

ProductState[ ProductState[a_Association, opts___],
  rule:(_?QubitQ -> {_, _}) ] :=
  ProductState[ KeySort @ Append[a, FlavorNone @ rule], opts ]

ProductState[
  ProductState[a_Association, opts___],
  rule:({__?QubitQ} -> {{_, _}..})
 ] := ProductState[
   KeySort @ Append[ a, FlavorNone @ Thread[rule] ],
   opts
  ]

ProductState[
  ProductState[a_Association, opts___],
  gg:{__?QubitQ} -> v:{_, _}
 ] := Module[
   { rr = Map[Rule[#, v]&, gg] },
   ProductState[ KeySort @ Append[a, FlavorNone @ rr], opts ]
  ]

(* Resetting the qubit values *)

ProductState[a_Association, otps___][v__Rule] :=
  ProductState[ ProductState[a, opts], v ]

(* Assessing the qubit values *)

ProductState[a_Association, opts___][qq:(_?QubitQ | {__?QubitQ})] :=
  Block[
    { Missing },
    Missing["KeyAbsent", _Symbol?QubitQ[___, None]] := {1, 0};
    Lookup[a, FlavorNone @ qq]
   ]


(**** <Ket for Qubit> ****)

KetTrim[_?QubitQ, 0] = Nothing

(**** </Ket for Qubit> ****)


(**** <Basis for Qubit> ****)

Basis[ S_?QubitQ ] := Ket /@ Thread[FlavorNone[S] -> {0, 1}]

(**** </Basis for Qubit> ****)


QuissoFactor::usage = "QuissoFactor is OBSOLETE. Use KetFactor instead."

QuissoFactor[expr__] := (
  Message[Q3`Q3General::obsolete, QuissoFactor, KetFactor];
  KetFactor[expr]
 )


(**** <SpinForm> ****)

SpinForm[vec:Ket[_Association], qq:{__?QubitQ}] := Module[
  { ss },
  ss = vec[FlavorNone @ qq] /. {
    0 -> "\[UpArrow]",
    1 -> "\[DownArrow]"
   };
  Ket[vec, qq -> ss]
 ]

(**** </SpinForm> ****)


(**** <PauliForm> ****)

PauliForm::usage = "PauliForm[expr] rewrites expr in a more conventional form, where the Pauli operators are denoted by I, X, Y, and Z."

HoldPattern @ PauliForm[Multiply[ss__?QubitQ], qq:{__?QubitQ}] :=
  PauliForm[ss, qq]

PauliForm[ss__?QubitQ, qq:{__?QubitQ}] := Module[
  { jj = Lookup[PositionIndex[FlavorNone @ qq], FlavorMute @ {ss}],
    mm },
  mm = FlavorLast @ {ss} /. {0 -> "I", 1 -> "X", 2 -> "Y", 3 -> "Z"};
  CircleTimes @@ ReplacePart[
    ConstantArray["I", Length @ qq],
    Flatten[ Thread /@ Thread[jj -> mm] ]
   ]
 ]

PauliForm[expr_] := PauliForm[expr, Qubits @ expr] /; FreeQ[expr, _Pauli]

PauliForm[expr_List, qq:{__?QubitQ}] := Map[PauliForm[#, qq]&, expr]

PauliForm[assc_Association, qq:{__?QubitQ}] := Map[PauliForm[#, qq]&, assc]
(* NOTE: For some unknown reason, a special handling is required for
   Association[...]. *)

PauliForm[expr_Plus, qq:{__?QubitQ}] :=
  Plus @@ PauliForm[List @@ expr, qq]

PauliForm[z_?CommutativeQ, qq:{__?QubitQ}] :=
  z * PauliForm[Multiply @@ Through @ qq[0], qq]

PauliForm[expr_, qq:{__?QubitQ}] := expr /. {
  HoldPattern @ Multiply[ss__?QubitQ] :> PauliForm[ss, qq],
  op_?QubitQ :> PauliForm[op, qq]
 }


PauliForm[op_Pauli] :=
  CircleTimes @@ ReplaceAll[op, {0 -> "I", 1 -> "X", 2 -> "Y", 3 -> "Z"}]

PauliForm[assc_Association] := Map[PauliForm, assc]
(* NOTE: For some unknown reason, a special handling is required for
   Association[...]. *)

PauliForm[expr_] := expr /. { op_Pauli :> PauliForm[op] }

(**** </PauliForm> ****)


(**** <Dirac> ****)

Dirac::usage = "Dirac is OBSOLETE. Instead, use Dyad."

Dirac[expr__] := (
  Message[Q3`Q3General::obsolete, Dirac, Dyad];
  Dyad[expr]
 )

(**** </Dirac> ****)


QuissoReduced::usage = "QuissoReduced[v, {S}] gives the reduced density operator (in the Ket[...]**Bra[...] form) for the qubits in {S}. For the single-qubit reduced density operator, QuissoReduced[v, S] can be used.
  QuissoReduced[v, {n}] for an integer n gives all n-qubit reduced densitry operators.
  QuissoReduced[v, n] for an integer n gives all k-qubit reduced densitry operators up to k = n.
  QuissoReduced[v] gives all n-qubit reduced densitry operators up to n = the number of qubits in v."

QuissoReduced[v_, S_?QubitQ] :=
  wReduced @ QuissoFactor[ Garner @ v, {S} ]

QuissoReduced[v_, S:{__?QubitQ}] :=
  wReduced @ QuissoFactor[ Garner @ v, S ]

wReduced[ OSlash[a_Ket, b_] ] :=
  Dyad[a, a] * (Dagger[b] ** b)

wReduced[ expr_Plus ] := Module[
  { vv = List @@ expr,
    aa, bb, qq },
  { aa, bb } = Transpose[vv /. {OSlash -> List}];
  qq = Qubits[aa];
  aa = Outer[ Dyad[#1, #2, qq]&, aa, aa ];
  bb = Outer[ Multiply, Dagger[bb], bb ];
  Total @ Flatten[ Conjugate[bb] * aa ]
 ]


QuissoReduced[v_] := With[
  { ss = Qubits @ v },
  QuissoReduced[ v, Length[ss]-1 ]
 ]

QuissoReduced[v_, n_Integer] :=
  Join @@ Table[ QuissoReduced[v, {k}], {k, 1, n} ]

QuissoReduced[v_, {n_Integer}] := Module[
  { ss = Qubits @ v,
    rr },
  ss = Subsets[ss, {n}];
  rr = Map[QuissoReduced[v,#]&, ss];
  Association[ Thread[ss->rr] ] /; n < Length[ss]
 ]

(* This is not really necessary, but just for completeness. *)
QuissoReduced[v_, {n_Integer}] := Module[
  { ss = Qubits @ v,
    rr },
  rr = v ** Dagger[v];
  Association[ ss -> rr ] /; n >= Length[ss]
 ]


ReducedDensityMatrix::usage = "ReducedDensityMatrix is almost the same as QuissoReduced, but returns the matrix representations."


ReducedDensityMatrix[v_, S_?QubitQ] :=
  Matrix[ QuissoReduced[v, {S}], {S} ]

ReducedDensityMatrix[v_, S:{__?QubitQ}] :=
  Matrix[ QuissoReduced[v, S], S ]

ReducedDensityMatrix[v_] := With[
  { ss = Qubits @ v },
  ReducedDensityMatrix[ v, Length[ss]-1 ]
 ]

ReducedDensityMatrix[v_, n_Integer] :=
  Join @@ Table[ ReducedDensityMatrix[v, {k}], {k, 1, n} ]

ReducedDensityMatrix[v_, {n_Integer}] := Module[
  { ss = Qubits @ v,
    rr },
  ss = Subsets[ss, {n}];
  rr = Map[ ReducedDensityMatrix[v,#]&, ss ];
  Association[ Thread[ss->rr] ] /; n < Length[ss]
 ]

ReducedDensityMatrix[v_, {n_Integer}] := Module[
  { ss = Qubits @ v,
    rr },
  rr = Matrix[ v ** Dagger[v], ss ];
  Association[ ss -> rr ] /; n >= Length[ss]
 ]


DensityMatrix::usage = "DensityMatrix[v] constructs the density matrix (in the matrix form) for the pure state v."

DensityMatrix[v_] := Module[
  { vv = Matrix[v] },
  vv = SparseArray[ ArrayRules[vv], Dimensions[vv] ];
  Outer[Times, vv, Conjugate[vv]]
 ]

DensityOperator::usage = "DensityOperator[v] constructs the operator expression for the density matrix corresponding to the pure state v."

DensityOperator[v_] := 
  ExpressionFor[DensityMatrix @ v, Qubits @ v]


(**** <Parity for Qubits> ****)

Parity[S_?QubitQ] := S[3]


ParityEvenQ[v_Ket, a_?QubitQ] := EvenQ @ v @ a

ParityOddQ[v_Ket, a_?QubitQ] := OddQ @ v @ a

(**** </Parity> ****)


(**** <Matrix for Qubits> ****)

TheMatrix[ _?QubitQ[___, j_] ] := ThePauli[j]

TheMatrix[ Ket[ Association[_?QubitQ -> s:(0|1)] ] ] := SparseArray @ TheKet[s]

(**** </Matrix> ****)


QuissoAddZ::usage = "QuissoAddZ[S$1, S$2, ...] returns in an Association the irreducible basis of the total angular momentum S$1 + S$2 + ... invariant under the U(1) rotation around spin z-axis, regarding the qubits S$1, S$2, ... as 1/2 spins."

QuissoAddZ::duplicate = "Duplicate angular momentum operators appear."


QuissoAddZ[ ls:{(_?QubitQ|_Association)..} ] :=
  QuissoAddZ @@ Map[QuissoAddZ] @ ls

QuissoAddZ[] := Association[ {0} -> {Ket[]} ]

QuissoAddZ[irb_Association] := irb

QuissoAddZ[a_?QubitQ] := Module[
  { aa = FlavorNone @ a,
    bs = Basis @ a },
  GroupBy[bs, (1/2-#[aa])&]
 ]

QuissoAddZ[a___, b_?QubitQ, c___] := QuissoAddZ[a, QuissoAddZ[b], c]

QuissoAddZ[irb_Association, irc_Association, ird__Association] :=
  QuissoAddZ[ QuissoAddZ[irb, irc], ird]

QuissoAddZ[irb_Association, irc_Association] := Module[
  { kk = Flatten @ Outer[Plus, Keys[irb], Keys[irc]],
    vv = Map[Tuples] @ Tuples[{Values[irb], Values[irc]}],
    gb = Union @ Cases[Normal @ Values @ irb, _?QubitQ, Infinity],
    gc = Union @ Cases[Normal @ Values @ irc, _?QubitQ, Infinity],
    rr },
  If[ ContainsAny[gb, gc],
    Message[ QuissoAddZ::duplicate ];
    Return[ irb ]
   ];

  vv = Apply[CircleTimes, vv, {2}];
  rr = Thread[kk -> vv];
  rr = Merge[rr, Catenate];
  Map[ReverseSort, rr]
 ]

QuissoAdd::usage = "QuissoAdd[S$1, S$2, ...] returns in an Association the irreducible basis of the total angular momentum S$1 + S$2 + ... that are invariant under arbitrary SU(2) rotations. Here the qubits S$1, S$2, ... are regarded 1/2 spins."

QuissoAdd::duplicate = "Duplicate angular momentum operators appear."

QuissoAdd[ ls:{(_?QubitQ|_Association)..} ] :=
  QuissoAdd @@ Map[QuissoAdd] @ ls

QuissoAdd[] := Association[ {0,0} -> {Ket[]} ]

QuissoAdd[irb_Association] := irb

QuissoAdd[a_?QubitQ] := Module[
  { aa = FlavorNone @ a,
    bs = Basis @ a },
  GroupBy[bs, { 1/2, (1/2 - #[aa]) }&]
 ]

QuissoAdd[a___, b_?QubitQ, c___] := QuissoAdd[a, QuissoAdd[b], c]

QuissoAdd[irb_Association, irc_Association, ird__Association] :=
  QuissoAdd[ QuissoAdd[irb, irc], ird]

QuissoAdd[irb_Association, irc_Association] := Module[
  { S1 = Union @ Map[First] @ Keys[irb],
    S2 = Union @ Map[First] @ Keys[irc],
    SS,
    gb = Union @ Cases[Normal @ Values @ irb, _?QubitQ, Infinity],
    gc = Union @ Cases[Normal @ Values @ irc, _?QubitQ, Infinity],
    new },
  If[ ContainsAny[gb, gc],
    Message[ QuissoAdd::duplicate ];
    Return[ irb ]
   ];
  SS = Flatten[
    Outer[Thread[{#1, #2, Range[Abs[#1 - #2], #1 + #2]}]&, S1, S2], 
    2];
  SS = Flatten[
    Map[Thread[{Sequence @@ #, Range[-Last@#, Last@#]}]&] @ SS,
    1];
  new = doQuissoAdd[irb, irc, #]& /@ SS;
  Merge[new, Catenate]
 ]

doQuissoAdd[irb_, irc_, {S1_, S2_, S_, Sz_}] := Module[
  { new, min, max },
  min = Max[-S1, Sz - S2, (Sz - (S1 + S2))/2];
  max = Min[S1, Sz + S2, (Sz + (S1 + S2))/2];
  new = Simplify @ Sum[
    CircleTimes @@@ Tuples[{irb[{S1, m}], irc[{S2, Sz - m}]}]*
      ClebschGordan[{S1, m}, {S2, Sz - m}, {S, Sz}],
    {m, Range[min, max]} ];
  Association[ {S, Sz} -> new ]
 ]


QuissoExpression::usage = "QuissoExpression is obsolete now. Use ExpressionFor instead."

QuissoExpression[args___] := (
  Message[Q3`Q3General::obsolete, "QuissoExpression", "ExpressionFor"];
  ExpressionFor[args]
 )


QuissoExpressionRL::usage = "QuissoExpressionRL is obsolete now. Use ExpressionFor instead."

QuissoExpressionRL[args___] := (
  Message[Q3`Q3General::obsolete, "QuissoExpressionRL", "ExpressionFor"];
  ExpressionFor[args]
 )


(**** <ExpressionFor> ****)

TheExpression[S_?QubitQ] := {
  {1/2 + S[3]/2, S[4]},
  {S[5], 1/2 - S[3]/2}
 }
(* NOTE: This makes ExpressionFor to generate an operator expression in terms
   of the Pauli raising and lowering operators instead of the Pauli X and Y
   operators. Many evaluations are faster with the raising and lowering
   operators rather than X and Y operators. When an expression in terms of the
   X and Y operators are necessary, one can use Elaborate. *)

(**** </ExpressionFor> ****)

(* QuissoCoefficientTensor *)

QuissoCoefficientTensor::usage = "QuissoCoefficientTensor[expr] gives the Pauli decomposition of the Quisso expression expr, by finding the coefficients to operators."


(* Method 1: One can use a similar method as in PauliDecompose[]. But it
   becomse very slow as the number of qubits increases. *)

(* Method 2: This results in "Recursion depth of 1024 exceeded
   during evaluation of ..." error when the state vector includes many terms
   for a large number of qubits. *)

QuissoCoefficientTensor[op_] := With[
  { ss = Qubits @ op },
  QuissoCoefficientTensor[op, Length[ss]]
 ]

QuissoCoefficientTensor[op_, n_Integer] :=
  Join @@ Table[ QuissoCoefficientTensor[op, {k}], {k, 0, n} ]

QuissoCoefficientTensor[op_, {0}] := With[
  { cn = Elaborate[op] /. {_Symbol?QubitQ[___,(1|2|3)] -> 0} },
  Association[ {1} -> cn ]
 ]

QuissoCoefficientTensor[expr_, {n_Integer}] := Module[
  { ss = Qubits @ expr,
    op = Elaborate @ expr,
    kk, cc },
  ss = Subsets[ss, {n}];
  kk = Map[ (#[{1,2,3}])&, ss, {2} ];
  ss = Map[ (#[None])&, ss, {2} ];
  cc = Map[ CoefficientTensor[op, Sequence @@ #]&, kk ];
  Association[ Thread[ss->cc] ]
 ]


(* QuissoAssemble *)

QuissoAssemble::usage = "QuissoAssemble[a] reassembles the operator expression in terms of operators from the coefficient tensors in the Association a. The association a is usually generated by QuissoCoefficientTensor[] or QuissoCorrelationTensor[]."

QuissoAssemble[ a_Association ] := Total @ KeyValueMap[ QuissoAssemble, a ]

QuissoAssemble[ {1}, m_ ] := m

QuissoAssemble[ ss:{__?QubitQ}, m_?TensorQ ] := Module[
  { kk, op, vv, nL },
  nL = Length[ss]; (* the level of Quisso decomposition *)
  kk = Outer[List, Sequence @@ Table[{1, 2, 3}, {nL}]];
  op = Map[ ( Multiply @@ MapThread[Construct, {ss, #}] )&, kk, {nL} ];
  vv = op * m;
  Total @ Flatten[vv]
 ]


(**** <Phase> ****)

Phase::usage = "Phase[G, \[Phi]] represents the relative phase shift by \[Phi] on the qubit G."

Options[Phase] = { "Label" -> "\[CapitalPhi]" }

Phase[phi_, qq:{__?QubitQ}, opts___?OptionQ] :=
  Map[Phase[phi, #, opts]&, FlavorNone @ qq]

Phase[phi_, S_?QubitQ, opts___?OptionQ] :=
  Phase[phi, S[None], opts] /; FlavorLast[S] =!= None


Phase /:
Dagger[ Phase[phi_, G_?QubitQ, opts___?OptionQ] ] :=
  Phase[-Conjugate[phi], G, opts]
  
Phase /:
HoldPattern @ Elaborate @ Phase[a_, S_?QubitQ, ___] :=
  (1+Exp[I*a])/2 + S[3] (1-Exp[I*a])/2

Phase /:
HoldPattern @ Multiply[pre___,
  Phase[phi_, S_?QubitQ, ___?OptionQ],
  post___] := Multiply[pre, Elaborate @ Phase[phi, S], post]
(* Options are for QuantumCircuit[] and ignored in calculations. *)

Phase /:
HoldPattern @ Matrix[op_Phase, rest__] := Matrix[Elaborate[op], rest]

Phase /:
HoldPattern @ Matrix @ Phase[a_, S_?QubitQ, ___] :=
  SparseArray[{{1, 1} -> 1, {2, 2} -> Exp[I a]}, {2, 2}]
(* NOTE: This is just a short-cut. *)


Phase[q_?QubitQ, ang_, rest___] := (
  Message[Q3`Q3General::newUI, Phase];
  Phase[ang, q, rest]
 )

Phase[qq:{__?QubitQ}, ang_, rest___] := (
  Message[Q3`Q3General::newUI, Phase];
  Phase[ang, qq, rest]
 )

QuissoPhase::usage = "QuissoPhase[...] is obsolete. Use Elaborate[Phase[...]] instead."

QuissoPhase[args___] := (
  Message[
    Q3`Q3General::obsolete,
    "QuissoPhase",
    "Elaborate[Phase[\[Ellipsis]]]"
   ];
  Elaborate @ Phase[args]
 )

(**** </Phase> ****)


(**** <Rotation and EulerRotation> ****)

Options[Rotation] = { "Label" -> Automatic }

Rotation[phi_, S_?QubitQ, v:{_, _, _}, opts___?OptionQ] :=
  Rotation[phi, S[None], v, opts] /;
  FlavorLast[S] =!= None

Rotation[phi_, qq:{__?QubitQ}, rest___] :=
  Map[Rotation[phi, #, rest]&, qq]
(* NOTE: NOT FlavorNone@qq because S[..., k] in qq may indicate the rotation
   axis. *)

Rotation /:
HoldPattern @ Multiply[pre___, op_Rotation, post___] :=
  Multiply[ pre, Elaborate[op], post ]

Rotation /:
Dagger[ Rotation[ang_, S_?QubitQ, rest___] ] :=
  Rotation[-Conjugate[ang], S, rest]

Rotation /:
HoldPattern @ Elaborate @ Rotation[phi_, S_?QubitQ, ___?OptionQ] :=
  Cos[phi/2] - I Sin[phi/2]*S

Rotation /:
HoldPattern @ Elaborate @ Rotation[phi_, S_?QubitQ, v:{_, _, _}, ___] :=
  Garner[ Cos[phi/2] - I Sin[phi/2] Dot[S @ All, Normalize @ v] ]

Rotation /:
HoldPattern @ Matrix[op_Rotation, rest___] := Matrix[Elaborate[op], rest]


Rotation[q_?QubitQ, ang_, rest___] := (
  Message[Q3`Q3General::newUI, Rotation];
  Rotation[ang, q, rest]
 )

Rotation[qq:{__?QubitQ}, ang_, rest___] := (
  Message[Q3`Q3General::newUI, Rotation];
  Rotation[ang, qq, rest]
 )


QuissoRotation::usage = "QuissoRotation is obsolete now. Use Elaborate[Rotation[...]] instead."

QuissoRotation[args___] := (
  Message[
    Q3`Q3General::obsolete,
    "QuissoRotation",
    "Elaborate[QuissoRotation[\[Ellipsis]]]"
   ];
  Elaborate @ Rotation[args]
 )


Options[EulerRotation] = { "Label" -> Automatic }

EulerRotation[aa:{_, _, _}, qq:{__?QubitQ}, rest___] :=
  Map[ EulerRotation[aa, #, rest]&, FlavorNone @ qq ]

EulerRotation[aa:{_, _, _}, G_?QubitQ, opts___?OptionQ] :=
  EulerRotation[ aa, G[None], opts ] /; FlavorLast[G] =!= None

EulerRotation /:
HoldPattern @ Multiply[pre___, op_EulerRotation, post___ ] :=
  Multiply[pre, Elaborate[op], post]

EulerRotation /:
HoldPattern @ Elaborate @ EulerRotation[{a_, b_, c_}, S_?QubitQ, ___] :=
  Garner @ Multiply[
    Elaborate @ Rotation[a, S[3]],
    Elaborate @ Rotation[b, S[2]],
    Elaborate @ Rotation[c, S[3]]
   ]

EulerRotation /:
HoldPattern @ Matrix[op_EulerRotation, rest___] := Matrix[Elaborate[op], rest]


EulerRotation[q_?QubitQ, ang_, rest___] := (
  Message[Q3`Q3General::newUI, EulerRotation];
  EulerRotation[ang, q, rest]
 )

EulerRotation[qq:{__?QubitQ}, ang_, rest___] := (
  Message[Q3`Q3General::newUI, EulerRotation];
  EulerRotation[ang, qq, rest]
 )

QuissoEulerRotation::usage = "QuissoEulerRotation is obsolete now. Use Elaborate[EulerRotation[\[Ellipsis]]] instead."

QuissoEulerRotation[args___] := (
  Message[Q3`Q3General::obsolete,
    "QuissoEulerRotation",
    "Elaborate[EulerRotation[\[Ellipsis]]]"
   ];
  Elaborate @ EulerRotation[args]
 )

(**** </Rotation and EulerRotation> ****)


(**** <CNOT> ****)

CNOT::usage = "CNOT[C, T] represents the CNOT gate on the two qubits C and T, which are the control and target qubits, respectively. Note that it does not expand until necessary (e.g., multiplied to a Ket); use QuissoCNOT or Elaborate in order to expand it immediately."

CNOT[c_?QubitQ, t_] := CNOT[{c}, t]

CNOT[c_, t_?QubitQ] := CNOT[c, {t}]

CNOT[cc:{__?QubitQ}, tt:{__?QubitQ}] :=
  CNOT[FlavorNone @ cc, FlavorNone @ tt] /;
  Not @ ContainsOnly[FlavorLast @ Join[cc, tt], {None}]

CNOT /:
Dagger[ op_CNOT ] := op

CNOT /:
HoldPattern @ Elaborate @ CNOT[cc:{__?QubitQ}, tt:{__?QubitQ}] := Module[
  { prj = Multiply @@ Through[cc[11]],
    not = Multiply @@ Through[tt[1]] },
  Garner @ Elaborate[(1-prj) + prj ** not]
 ]

CNOT /:
HoldPattern @ Multiply[pre___, op_CNOT, post___] :=
  Multiply[pre, Elaborate[op], post]

CNOT /:
HoldPattern @ Matrix[op_CNOT, rest___] := Matrix[Elaborate[op], rest]


QuissoCNOT::usage = "QuissoCNOT is obsolete now. Use Elaborate[CNOT[\[Ellipsis]]] instead."

QuissoCNOT[args___] := (
  Message[
    Q3`Q3General::obsolete,
    "CNOT",
    "Elaborate[CNOT[\[Ellipsis]]]"
   ];
  Elaborate @ CNOT[args]
 )

(**** </CNOT> ****)


(**** <CZ> ****)

CZ::usage = "CZ[C, T] operates the controlled-Z gate on the two qubits associated with C and T. C and T are the control and target qubits, respectively; in fact, contol and target qubits are symmetric for this gate."

SetAttributes[CZ, Listable]

CZ[ c_?QubitQ, t_?QubitQ ] := CZ @@ FlavorNone @ {c,t} /;
  FlavorLast[{c,t}] =!= {None, None}

CZ /:
Dagger[ op_CZ ] := op

CZ /:
HoldPattern @ Elaborate @ CZ[c_?QubitQ, t_?QubitQ] := Module[
  { a = Most @ c,
    b = Most @ t },
  Garner[ (1 - a[3]**b[3] + a[3] + b[3]) / 2 ]
 ]

CZ /:
HoldPattern @ Multiply[pre___, op_CZ, post___] :=
  Multiply[pre, Elaborate[op], post]

CZ /:
HoldPattern @ Matrix[op_CZ, rest___] := Matrix[Elaborate[op], rest]


QuissoCZ::usage = "QuissoCZ is obsolete now. Use Elaborate[CZ[\[Ellipsis]]] instead."

QuissoCZ[args___] := (
  Message[
    Q3`Q3General::obsolete,
    "CZ",
    "Elaborate[CZ[\[Ellipsis]]]"
   ];
  Elaborate @ CZ[args]
 )

(**** </CZ> ****)


(**** <SWAP> ****)

SWAP::usage = "SWAP[A, B] operates the SWAP gate on the two qubits A and B."

SetAttributes[SWAP, Listable]

SWAP[a_?QubitQ, b_?QubitQ] := SWAP @@ FlavorNone @ {a, b} /;
  FlavorLast[{a, b}] =!= {None, None}

SWAP /:
Dagger[ op_SWAP ] := op

SWAP /:
HoldPattern @ Elaborate @ SWAP[x_?QubitQ, y_?QubitQ] := Module[
  { a = Most @ x,
    b = Most @ y },
  Garner[ (1 + a[1]**b[1] + a[2]**b[2] + a[3]**b[3]) / 2 ]
 ]

SWAP /:
HoldPattern @ Multiply[pre___, op_SWAP, post___] :=
  Multiply[pre, Elaborate[op], post]

SWAP /:
HoldPattern @ Matrix[op_SWAP, rest___] := Matrix[Elaborate[op], rest]


QuissoSWAP::usage = "QuissoSWAP is obsolete now. Use Elaborate[SWAP[\[Ellipsis]]] instead."

QuissoSWAP[args___] := (
  Message[
    Q3`Q3General::obsolete,
    "SWAP",
    "Elaborate[SWAP[\[Ellipsis]]]"
   ];
  Elaborate @ SWAP[args]
 )

(**** </SWAP> ****)


(**** <Toffoli> ****)

Toffoli::usage = "Toffoli[A, B, C] operates the Toffoli gate, i.e., the three-qubit controlled-note gate on C controlled by A and B."

QuissoToffoli::usage = "QuissoToffoli[A, B, C] is the same as Toffoli[A, B, C], but expands immediately in terms of elementary Pauli gates."

SetAttributes[Toffoli, Listable]

Toffoli[a_?QubitQ, b_?QubitQ, c_?QubitQ] :=
  Toffoli @@ FlavorNone @ {a, b, c} /;
  FlavorLast[{a, b, c}] =!= {None, None, None}

Toffoli /:
Dagger[ op_Toffoli ] := op

Toffoli /:
HoldPattern @ Elaborate @ Toffoli[a_?QubitQ, b_?QubitQ, c_?QubitQ] := Garner[
  ( 3 + a[3] + b[3] + c[1] -
      a[3]**b[3] - a[3]**c[1] - b[3]**c[1] +
      a[3]**b[3]**c[1]
   ) / 4
 ]

Toffoli /:
HoldPattern @ Multiply[pre___, op_Toffoli, post___] :=
  Multiply[pre, Elaborate[op], post]

Toffoli /:
HoldPattern @ Matrix[op_Toffoli, rest___] := Matrix[Elaborate[op], rest]


QuissoToffoli::usage = "QuissoToffoli is obsolete now. Use Elaborate[Toffoli[\[Ellipsis]]] instead."

QuissoToffoli[args___] := (
  Message[
    Q3`Q3General::obsolete,
    "Toffoli",
    "Elaborate[Toffoli[\[Ellipsis]]]"
   ];
  Elaborate @ Toffoli[args]
 )

(**** </Toffoli> ****)


(**** <Fredkin> ****)

Fredkin::usage = "Fredkin[a, b, c] represents the Fredkin gate, i.e., the SWAP gate on b and c controlled by a."

SetAttributes[Fredkin, Listable]

Fredkin[ a_?QubitQ, b_?QubitQ, c_?QubitQ ] :=
  Fredkin @@ FlavorNone @ {a,b,c} /;
  Not @ ContainsOnly[FlavorLast @ {a,b,c}, {None}]

Fredkin /:
Dagger[ op_Fredkin ] := op

Fredkin /:
HoldPattern @ Elaborate @ Fredkin[a_?QubitQ, b_?QubitQ, c_?QubitQ] :=
  Garner @ Elaborate[ a[10] + a[11] ** SWAP[b, c] ]

Fredkin /:
HoldPattern @ Multiply[pre___, op_Fredkin, post___] :=
  Multiply[pre, Elaborate[op], post]

Fredkin /:
HoldPattern @ Matrix[op_Fredkin, rest___] := Matrix[Elaborate[op], rest]


QuissoFredkin::usage = "QuissoFredkin is obsolete now. Use Elaborate[Fredkin[\[Ellipsis]]] instead."

QuissoFredkin[args___] := (
  Message[
    Q3`Q3General::obsolete,
    "Fredkin",
    "Elaborate[Fredkin[\[Ellipsis]]]"
   ];
  Elaborate @ Fredkin[args]
 )

(**** </Fredkin> ****)


(**** <ControlledU> ****)

ControlledU::usage = "ControlledU[{C1, C2, ...}, T[j, ..., k]] represents a multi-qubit controlled-U gate. It operates the gate T[j, ..., k] on the qubit T[j, ..., None] controlled by the qubits C1, C2.\nControlledU[C, T] is equivalent to ControlledU[{C}, T].\nControlledU[{C1, C2, ...}, expr] represents a general controlled gate operating expr on the qubits involved in it."

ControlledU::nonuni = "The operator `` is not unitary."

ControlledU[ S_?QubitQ, expr_, opts___?OptionQ ] :=
  ControlledU[ { S[None] }, expr, opts ]

ControlledU[ ss:{__?QubitQ}, expr_, opts___?OptionQ ] :=
  ControlledU[ FlavorNone @ ss, expr, opts ] /;
  Not @ ContainsOnly[ FlavorLast[ss], {None} ]


ControlledU[ ss:{__?QubitQ}, z_?CommutativeQ, opts___?OptionQ] := (
  If[ Abs[z] != 1, Message[ControlledU::nonuni, z] ];
  If[ Length[ss] > 1,
    ControlledU[Most @ ss, Phase[Arg[z], Last @ ss, opts]],
    Phase[Arg[z], Last @ ss, opts]
   ]
 )

ControlledU /:
Dagger[ ControlledU[ S_?QubitQ, expr_, opts___?OptionQ ] ] :=
  ControlledU[ { S[None] }, Dagger[expr], opts ]

ControlledU /:
Dagger[ ControlledU[ ss:{__?QubitQ}, expr_, opts___?OptionQ ] ] :=
  ControlledU[ss, Dagger[expr], opts]

ControlledU /:
HoldPattern @ Elaborate @ ControlledU[ss:{__?QubitQ}, expr_, ___] :=
  Module[
    { P = Multiply @@ Map[ ((1-#[3])/2)&, Most /@ ss ] },
    Garner[ P ** Elaborate[expr] + (1-P) ]
   ]

ControlledU /:
HoldPattern @ Matrix[op_ControlledU, rest___] := Matrix[Elaborate[op], rest]

ControlledU /:
HoldPattern @ Multiply[pre___, op_ControlledU, post___] :=
  Multiply[pre, Elaborate[op], post]
(* Options are for QuantumCircuit[] and ignored in calculations. *)


QuissoControlledU::usage = "QuissoControlledU[...] is obsolete. Use Elaborate[ControlledU[...]] instead."

QuissoControlledU[args___] := (
  Message[
    Q3`Q3General::obsolete,
    "QuissoControlledU",
    "Elaborate[ControlledU[...]]"
   ];
  Elaborate @ ControlledU[args]
 )

(**** </ControlledU> ****)


(**** <Oracle> ****)

Oracle::usage = "Oracle[f, control, target] represents the quantum oracle which maps Ket[x]\[CircleTimes]Ket[y] to Ket[x]\[CircleTimes]Ket[f(x)\[CirclePlus]y]. Each control and target can be list of qubits."

Oracle /:
NonCommutativeQ[ Oracle[___] ] = True

Oracle[f_, c_?QubitQ, t_?QubitQ, opts___?OptionQ] :=
  Oracle[f, {c}, {t}, opts]

Oracle[f_, c_?QubitQ, tt:{__?QubitQ}, opts___?OptionQ] :=
  Oracle[f, {c}, tt, opts]

Oracle[f_, cc:{__?QubitQ}, t_?QubitQ, opts___?OptionQ] :=
  Oracle[f, cc, {t}, opts]

Oracle[f_, cc:{__?QubitQ}, tt:{__?QubitQ}, opts___?OptionQ] :=
  Oracle[f, FlavorNone @ cc, FlavorNone @ tt, opts] /;
  Not @ ContainsOnly[ FlavorLast @ Join[cc, tt], {None} ]

Oracle /:
Dagger[op_Oracle] := op

Oracle /:
HoldPattern @ Multiply[pre___, op_Oracle, post___] :=
  Multiply[pre, Elaborate[op], post]

Oracle /:
HoldPattern @ Elaborate @ Oracle[f_, cc:{__?QubitQ}, tt:{__?QubitQ}] := Module[
  { cn = Length @ cc,
    cN, bb, ff },

  If[ FailureQ @ VerifyOracle[f, cc, tt],
    Return @ One @ Power[2, Length[cc] + Length[tt]]
   ];
  
  ff[x_List] := Flatten @ List[f @@ x];

  cN = Power[2, cn];
  bb = GroupBy[ IntegerDigits[Range[0, cN - 1], 2, cn], ff ];
  bb = ReplaceAll[bb, {0 -> 10, 1 -> 11}];
  Elaborate @ Total @ KeyValueMap[qtmOracle[cc, tt], bb]
 ]

qtmOracle[cc_, tt_][key_, val_] := Module[
  { onC = Multiply @@@ FlavorThread[cc, val],
    onT = Multiply @@ FlavorThread[tt, key] },
  Elaborate[Total @ onC] ** onT
 ]

Oracle /:
HoldPattern @ Matrix[op_Oracle, rest__] := Matrix[Elaborate[op], rest]

Oracle /:
HoldPattern @ Matrix[Oracle[args__]] := matOracle[args]

matOracle[f_, c_?QubitQ, t_?QubitQ] := matOracle[f, {c}, {t}]

matOracle[f_, c_?QubitQ, tt:{__?QubitQ}] := matOracle[f, {c}, tt]

matOracle[f_, cc:{__?QubitQ}, t_?QubitQ] := matOracle[f, cc, {t}]

matOracle[f_, cc:{__?QubitQ}, tt:{__?QubitQ}] := Module[
  { cn = Length @ cc,
    cN, bb, ff },

  If[ FailureQ @ VerifyOracle[f, cc, tt],
    Return @ One @ Power[2, Length[cc] + Length[tt]]
   ];
  
  ff[x_List] := Flatten @ List[f @@ x];

  cN = Power[2, cn];
  bb = GroupBy[ IntegerDigits[Range[0, cN - 1], 2, cn], ff ];
  Total @ KeyValueMap[ matOracle[#1, #2, cN]&, bb ]
 ]

matOracle[key:{(0|1)..}, val_List, n_Integer] := Module[
  { jj, matC, matT },
  jj = 1 + Map[FromDigits[#, 2]&, val];
  matC = SparseArray[Thread[Transpose@{jj, jj} -> 1], {n, n}];
  matT = ThePauli @@ key;
  CircleTimes[matC, matT]
 ]


VerifyOracle::usage = "VerifyOracle[f, {c1, c2, ...}, {t1, t2, ...}] checks if the classical oracle f is properly defined consistently with the control qubits {c1, c2, ...} and the target qubits {t1, t2, ...}.\nVerifyOracle[f, m, n] checks if the classical oracle f is a properly defined mapping consistent with m control qubits and n target qubits."

VerifyOracle::undef = "Either undefined or improperly defined values: ``"

VerifyOracle::range = "Expected is a mapping ``:{0,1\!\(\*SuperscriptBox[\(}\),``]\)\[RightArrow]{0,1\!\(\*SuperscriptBox[\(}\),``]\). Check the classical oracle again."

VerifyOracle[f_, cc : {__?QubitQ}, tt : {__?QubitQ}] :=  
  VerifyOracle[f, Length@cc, Length@tt]

VerifyOracle[f_, m_Integer, n_Integer] := Module[
  { in = IntegerDigits[Range[0, 2^m - 1], 2, m],
    ff, out, pos },
  ff[x_List] := Flatten@List[f @@ x];
  out = ff /@ in;
  pos = Position[out, Except[0 | 1], {2}, Heads -> False];
  If[ pos != {},
    Message[VerifyOracle::undef, Extract[out, pos]];
    Return[$Failed]
   ];
  If[ Not[ MatrixQ[out] && Dimensions[out] == {2^m, n} ],
    Message[VerifyOracle::range, f, m, n];
    Return[$Failed]
   ];
 ]


QuissoOracle::usage = "QuissoOracle[...] is obsolete. Use Elaborate[Oracle[...]] instead."

QuissoOracle[args___] := (
  Message[
    Q3`Q3General::obsolete,
    "QuissoOracle",
    "Elaborate[Oracle[...]]"
   ];
  Elaborate @ Oracle[args]
 )

(**** </Oracle> ****)


(**** <QuantumFourierTransform> ****)

QuantumFourierTransform::usage = "QuantumFourierTransform[{S1, S2, \[Ellipsis]}] represents the quantum Fourier transform on the qubits S1, S2, \[Ellipsis].\nDagger[QuantumFourierTransform[\[Ellipsis]]] represents the inverse quantum Fourier transform.\nElaborate[QuantumFourierTransform[\[Ellipsis]]] returns the explicit expression of the operator in terms of the Pauli operators."

Options[QuantumFourierTransform] = {
  "Label" -> "QFT",
  "LabelRotation" -> Pi/2
 }

QuantumFourierTransform[S_?QubitQ] := S[6]

QuantumFourierTransform @ {S_?QubitQ} := S[6]

QuantumFourierTransform[qq:{__?QubitQ}, opts___?OptionQ] :=
  QuantumFourierTransform[FlavorNone @ qq, opts] /;
  Not @ ContainsOnly[FlavorLast[qq], {None}]

QuantumFourierTransform /:
HoldPattern @ Elaborate @
  QuantumFourierTransform[qq:{__?QubitQ}, opts___?OptionQ] :=
  ExpressionFor[FourierMatrix @ Power[2, Length @ qq], qq]

QuantumFourierTransform /:
HoldPattern @ Matrix[op_QuantumFourierTransform, rest__] :=
  Matrix[Elaborate[op], rest]

QuantumFourierTransform /:
HoldPattern @ Matrix @ QuantumFourierTransform[qq:{__?QubitQ}, ___] :=
  FourierMatrix @ Power[2, Length @ qq]


(**** </QuantumFourierTransform> ****)


Projector::usage = "Projector[state, {q1, q2, ...}] represents the projection operator on the qubits {q1, q2, ...} into state, which is given in the Ket expression.\nProjector[expr] automatically extracts the list of qubits from expr."

Projector::noKet = "No Ket expression found for projection in the provided expression ``. Identity operator is returned."

Projector /:
Dagger[ op_Projector ] := op

Projector /:
HoldPattern @ Elaborate[ Projector[v_, qq_] ] :=
  Elaborate[Dyad[v, v, qq]]

Projector /:
HoldPattern @ ExpressionFor[ Projector[v_, qq_] ] :=
  Dyad[v, v, qq]

HoldPattern @ Projector[expr_, ___] := (
  Message[Projector::noKet, expr];
  1
 ) /; FreeQ[expr, _Ket]

HoldPattern @ Projector[expr_] := Projector[expr, Qubits @ expr]

HoldPattern @ Projector[expr_, {}] := 1

HoldPattern @ Projector[expr_, q_?QubitQ] := Projector[expr, FlavorNone @ {q}]

HoldPattern @
  Projector[expr_, qq:{__?QubitQ}] := Projector[expr, FlavorNone @ qq] /;
  Not @ ContainsOnly[ FlavorLast[qq], {None} ]


Measurement::usage = "Measurement[expr, {s1, s2, ...}] performs the projective measurements on the Qubits {s1, s2, ...}.\nMeasurement[expr, s] is equivalent to Measurement[expr, {s}].\nMeasurement[s] represents the projective measurement on the qubit s and returns the state vector corresponding to the measurement outcome.\nMeasurement[{s1, s2, ...}] is equivalent to Map[Measurement, {s1, s2, ...}]."

Measurement::nonum = "Cannot perform a measurement on a nonnumeric state vector. Probability half is assumed."

Measurement::novec = "The expression `` does not seem to be a valid Quisso Ket expression. Null vector is returned."

Measurement[ gg:{__?QubitQ} ] := Measurement /@ FlavorNone @ gg

Measurement[ g_?QubitQ ] := Measurement @ FlavorNone @ g /;
  FlavorLast[g] =!= None
(* This is for the interface with QuantumCircuit[]. *)

Measurement[vec_, qq:{__?QubitQ}] :=
  Fold[ Measurement, vec, FlavorNone @ qq ] /;
  Not @ FreeQ[Elaborate[vec], Ket[_Association]]

Measurement[vec_, S_?QubitQ] := Module[
  { r = RandomReal[],
    b = FlavorNone[S],
    expr = Elaborate @ vec,
    vx, v0, v1, p0, p1 },
  vx = Cases[expr, v:Ket[_Association] :> v[b], Infinity];
  vx = DeleteCases[vx, (0|1)];
  If[ vx == {},
    Null,
    Message[Measurement::novec, expr]; Return[0],
    Message[Measurement::novec, expr]; Return[0]
   ];

  v0 = expr /. { v:Ket[_Association] :> (1-v[b]) v };
  v1 = expr /. { v:Ket[_Association] :> (v[b]) v };

  p0 = Re @ Simplify[ Dagger[v0] ** v0 ];
  p1 = Re @ Simplify[ Dagger[v1] ** v1 ];
  
  If [ r < N[p0 / (p0 + p1)],
    v0 / Sqrt[p0],
    v1 / Sqrt[p1],
    Message[Measurement::nonum];
    If[ r < 0.5, v0, v1 ]
   ]
 ] /; Not @ FreeQ[Elaborate[vec], Ket[_Association]]


(* DANGEROUS because Multiply is a multi-linear function. *)
(*
HoldPattern @ Multiply[pre___, Measurement[op_, q_?QubitQ], post___] :=
  Multiply[pre, Measurement[Multiply[op, post], q]]
 *)
(* NOTE: This occurs when op is not a Ket[<|...|>] expression. *)


Readout::usage = "Readout[expr, S] or Readout[expr, {S1, S2, ...}] reads the measurement result from the expr that is supposed to be the state vector after measurements."

Readout::badout = "Multiple measurement results: ``. The Qubit may not have been measured; or, it may have been corrupted after measurement."

Readout[expr_, S_?QubitQ] := First @ Readout[expr, {S}]

Readout[expr_, ss:{__?QubitQ}] := Module[
  { vv = Cases[{expr}, Ket[_Association], Infinity] },
  vv = Union @ Map[#[ss]&, vv];
  If[ Length[vv] > 1, Message[Readout::badout, vv] ];
  First @ vv
 ]


BellState::usage = "BellState[{S$1, S$2}, n] with n=0,1,2,3 gives the nth Bell states on the two qubits S$1 and S$2.
  BellState[{S$1, S$2}] returns the list of all Bell states."

BellState[g:{_?QubitQ, _?QubitQ}] :=
  Table[ BellState[g, j], {j, 0, 3} ]

BellState[g:{_?QubitQ, _?QubitQ}, 0] :=
  ( Ket[g->{0,0}] + Ket[g->{1,1}] ) / Sqrt[2]

BellState[g:{_?QubitQ, _?QubitQ}, 1] :=
  ( Ket[g->{0,1}] + Ket[g->{1,0}] ) / Sqrt[2]

BellState[g:{_?QubitQ, _?QubitQ}, 2] :=
  ( Ket[g->{0,1}] - Ket[g->{1,0}] ) / Sqrt[2]

BellState[g:{_?QubitQ, _?QubitQ}, 3] :=
  ( Ket[g->{0,0}] - Ket[g->{1,1}] ) / Sqrt[2]


DickeState::usage = "DickeState[qubits, n] gives the generalized Dicke state for the qubits, where n qubits are in the state Ket[1]."

DickeState[ss:{__?QubitQ}, n_] := Module[
  { byte = ConstantArray[1, n] },
  byte = PadRight[byte, Length @ ss];
  byte = Permutations[byte];
  Total[ Map[Ket[ss -> #]&, byte] ] / Sqrt[Length[byte]]
 ]

DickeState[ss:{__?QubitQ}] := Table[DickeState[ss, n], {n, 0, Length @ ss}]


RandomState::usage = "RandomState[{S1,S2,...}] gives a normalized random state for the system of multiple qubits {S1,S2,...}.
  RandomState[{S1,S2,...}, n] gives n mutually orthogonal normalized random states."

RandomState[S_?QubitQ] := RandomState[{S}]

RandomState[S_?QubitQ, n_Integer] := RandomState[{S}, n]

RandomState[qq : {__?QubitQ}] := Module[
  { cc = RandomComplex[{-1 - I, 1 + I}, Power[2, Length[qq]]] },
  cc = Normalize[cc];
  cc.Basis[qq]
 ]

RandomState[qq : {__?QubitQ}, n_Integer] := Module[
  { bb = Basis[qq],
    dd = Power[2, Length[qq]],
    cc },
  cc = RandomComplex[{-1 - I, 1 + I}, n * dd];
  cc = Partition[cc, dd];
  cc = Orthogonalize[cc];
  Map[ (#.bb)&, cc ]
 ]


GraphState::usage = "GraphState[g] gives the graph state (aka cluster state) correponding to the graph g."

GraphState[ g_Graph ] := Module[
  { vv = VertexList[g],
    cz = EdgeList[g],
    hh },
  hh = Multiply @@ Map[#[6]&, vv];
  cz = Multiply @@ CZ @@@ cz; 
  Garner[ cz ** (hh ** Ket[]) ]
  /; AllTrue[ vv, QubitQ ]
 ]


Protect[Evaluate @ $symb]

End[] (* `Private` *)



Begin["`Circuit`"]

QuissoCircuit::usage = "QuissoCircuit has been renamed QuantumCircuit."

QuissoCircuit[args___] := (
  Message[Q3`Q3General::renamed, "QuissoCircuit", "QuantumCircuit"];
  QuantumCircuit[args]
 )


QuantumCircuit::usage = "QuantumCircuit[a, b, ...] represents the quantum circuit model consisting of the gate operations a, b, ..., and it is displayed the circuit in a graphical form.\nExpressionFor[ QuantumCircuit[...] ] takes the non-commutative product of the elements in the quantum circuit; namely, converts the quantum circuit to a Quisso expression.\nMatrix[ QuantumCircuit[...] ] returns the matrix representation of the quantum circuit model."

QuantumCircuit::noqubit = "No Qubit found in the expression ``. Use LogicalForm to specify the Qubits explicitly."

QuantumCircuit::nofunc = "Unknown function \"``\" to draw the gate. \"Rectangle\" is assumed."

QuissoIn::usage = "QuissoIn is a holder for input expression in QuantumCircuit.\nSee also QuissoOut."

QuissoOut::usage = "QuissoOut is a holder for expected output expressions in QuantumCircuit. Note that the output expressions are just expected output and may be different from the actual output. They are used only for output label and ignored by ExpressionFor and Elaborate.\nSee also QuissoIn."


SetAttributes[ {QuissoOut, QuissoIn}, Flat ]

Options[QuantumCircuit] = {
  "TargetFunction" -> "Rectangle",
  "ControlFunction" -> "Dot",
  "UnitLength" -> 36,
  "PortSize" -> 0.65,
  "LabelSize" -> 1, 
  "Label" -> Automatic,
  "Visible" -> {},
  "Invisible" -> {}
 }

$CircuitSize = 1

$CircuitUnit = 1

$GateSize := 0.8 $CircuitUnit

$DotSize := 0.09 $CircuitUnit

$InOutOffset := 0.1 $CircuitUnit

$BraceWidth := 0.1 $CircuitUnit


Format[ qc:QuantumCircuit[__, opts___?OptionQ] ] := Graphics[qc]

(*
 * Multiply
 *)

QuantumCircuit /:
NonCommutativeQ[ QuantumCircuit[__] ] = True

QuantumCircuit /:
Kind[ QuantumCircuit[__] ] = NonCommutative

QuantumCircuit /:
MultiplyGenus[ QuantumCircuit[__] ] := "QuantumCircuit"

HoldPattern @ Multiply[
  Longest[pre___],
  QuantumCircuit[elm__], Longest[v__Ket],
  post___] := Multiply[pre, Elaborate @ QuantumCircuit[v, elm], post]
  
HoldPattern @ Multiply[pre___, Longest[qc__QuantumCircuit], post___] :=
  Multiply[pre, Multiply @@ Map[Elaborate, {qc}], post]

(*
 * User Interface
 *)

QuantumCircuit[ a___, QuantumCircuit[b___], c___] := QuantumCircuit[a, b, c]
(* Similar effect as the Flat attribute. *)

QuantumCircuit[ a__?qKetQ ] := QuantumCircuit[ QuissoIn[a] ]

QuantumCircuit[ a__?qKetQ, b:Except[_?qKetQ], c___ ] :=
  QuantumCircuit[ QuissoIn[a], b, c ]

QuantumCircuit[ a___, b__?qKetQ, opts___?OptionQ ] :=
  QuantumCircuit[ a, QuissoOut[b], opts ]

QuantumCircuit[ a___, b__?OptionQ, c:Except[_?OptionQ].. ] :=
  QuantumCircuit[a, c, b]

QuantumCircuit[ x___, a_QuissoOut, b__QuissoOut, y___ ] :=
  QuantumCircuit[x, QuissoOut[a, b], y]

QuantumCircuit[ x___, a_QuissoIn, b__QuissoIn, y___ ] :=
  QuantumCircuit[x, QuissoIn[a, b], y]

QuantumCircuit[ a__, b_QuissoIn, c___ ] := QuantumCircuit[ b, a, c ]

QuantumCircuit[ a___, b_QuissoOut, c:Except[_?OptionQ].., opts___?OptionQ ] :=
  QuantumCircuit[a, c, b, opts]

qKetQ[expr_] := And[
  FreeQ[expr, _QuissoIn | _QuissoOut | _Projector],
  !FreeQ[expr, _Ket | _ProductState]
 ]

(* See also GraphState[] *)
QuantumCircuit[a___, g_Graph, b___] := Module[
  { qubits = VertexList[g],
    links  = EdgeList[g] },
  links = links /. { UndirectedEdge -> CZ };
  QuantumCircuit[a, Map[#[6]&] @ qubits, Sequence @@ links, b]
  /; AllTrue[ qubits, QubitQ ]
 ]

(*
 * ExpressionFor and Matrix on QuantumCircuit
 *)

QuantumCircuit /:
ExpressionFor[ qc_QuantumCircuit ] := Elaborate[ qc ]

QuantumCircuit /:
Elaborate[ QuantumCircuit[gg__, ___?OptionQ] ] := Module[
  { expr = Flatten @ QuantumCircuitTrim @ {gg} },
  Garner[ qCircuitOperate @@ expr ]
 ]
(* NOTE: This makes the evaluation much faster, especially, when the initial
   state is specified in the circuit. *)

QuantumCircuit /:
Qubits[ QuantumCircuit[gg__, opts___?OptionQ] ] := Union[
  Qubits @ {gg},
  FlavorNone @ Flatten[
    {"Visible"} /. {opts} /. Options[QuantumCircuit]
   ]
 ]

QuantumCircuit /:
Matrix[ qc:QuantumCircuit[gg__, ___?OptionQ] ] := Module[
  { expr = Flatten @ QuantumCircuitTrim @ {gg} },
  qCircuitMatrix[ Sequence @@ expr, Qubits @ qc ]
 ]


qCircuitOperate::usage = "Converts gates to operators ..."

qCircuitOperate[] = 1

qCircuitOperate[pre__, Measurement[q_?QubitQ], post___] := 
  qCircuitOperate[ Measurement[qCircuitOperate[pre], q], post ]

qCircuitOperate[m_Measurement, post___] :=
  Multiply[qCircuitOperate[post], m]

qCircuitOperate[ op:Except[_Measurement].. ] :=
  Fold[ Garner @ Multiply[#2, #1]&, 1, Elaborate @ {op} ]


qCircuitMatrix::usage = "Based on Matrix[] ..."

qCircuitMatrix[pre___, Measurement[q_?QubitQ], post___,  qq:{__?QubitQ}] :=
  With[
    { ss = Qubits @ {pre, q} },
    qCircuitMatrix[
      Measurement[ ExpressionFor[qCircuitMatrix[pre, ss], ss], q ],
      post,
      qq
     ]
   ]

qCircuitMatrix[op:Except[_Measurement].., qq:{__?QubitQ}] := Module[
  { new },
  new = Map[Topple] @ Map[Matrix[#, qq]&] @ Elaborate @ {op};
  Topple[ Dot @@ new ]
 ]


QuantumCircuitTrim::usage = "QuantumCircuitTrim[expr] removes visualization options and Graphics Directives that are not evaluable expressions. Useful to convert QuantumCircuit to an evaluation-ready expression."

SetAttributes[ QuantumCircuitTrim, Listable ];

QuantumCircuitTrim[ QuantumCircuit[gg__] ] :=
  Flatten @ QuantumCircuitTrim @ {gg}

QuantumCircuitTrim[ QuissoIn[a__] ]  := Multiply @@ QuantumCircuitTrim[ {a} ]
(* NOTE: Useful to apply Matrix directly to QuantumCircuit.  *)

QuantumCircuitTrim[ _QuissoOut ] = Nothing

QuantumCircuitTrim[ _?OptionQ ] = Nothing

QuantumCircuitTrim[ g_ ] := Nothing /;
  FreeQ[ g, _?QubitQ | _Ket | _ProductState ]

QuantumCircuitTrim[ HoldPattern @ Projector[v_, qq_, ___?OptionQ] ] :=
  Dyad[v, v, qq]

QuantumCircuitTrim[ v:ProductState[_Association, ___] ] := Expand[v]

QuantumCircuitTrim[ Gate[expr_, ___?OptionQ] ] := expr

QuantumCircuitTrim[ op_Symbol[expr__, ___?OptionQ] ] := op[expr]

QuantumCircuitTrim[ g_?NumericQ ] := g

QuantumCircuitTrim[ g_ ] := g


(*
 * Graphical display of circuit
 *)

QuantumCircuit /:
Graphics[ QuantumCircuit[ gg__, opts___?OptionQ ], more___?OptionQ ] :=
  Module[
    { ss = Qubits @ {gg},
      (* NOTE: Pure Qubits should be given None index properly. *)
      cc = qCircuitGate @ gg,
      vv, ww, xx, yy, nodes, lines, in, out, unit },

    {vv, ww, unit, port} = {
      {"Visible"}, {"Invisible"},
      "UnitLength", "PortSize"
     } /. {opts} /. Options[QuantumCircuit];

    If[ ListQ[port], Null, port = {port, port} ];

    vv = FlavorNone @ Flatten @ vv;
    ww = FlavorNone @ Flatten @ ww;
    ss = Union @ Flatten @ {ss, vv, ww};

    If[ !ListQ[cc], cc = List @ cc ];
    (* It happens when there is only one circuit element. *)

    If[ cc == {}, cc = {"Spacer"} ];
    (* There can be only input elements. *)
    
    xx  = Accumulate @ Boole[ qGateQ /@ cc ];
    xx *= $CircuitUnit;
    $CircuitSize = $CircuitUnit + Max[xx];
    
    yy = Range[ Length @ ss ] $CircuitUnit;
    yy = AssociationThread[ss, -yy];
    
    nodes = qCircuitNodes[ cc, xx, yy ];
    lines = qCircuitLines[ cc, xx, KeyDrop[yy, ww] ];
    
    in = FirstCase[ {gg}, QuissoIn[kk___] :> {kk} ];
    in = qCircuitInput[ in, xx, yy ];

    out = FirstCase[ {gg}, QuissoOut[kk___] :> {kk} ];
    out = qCircuitOutput[ out, xx, yy ];

    Graphics[ Join[lines, in, nodes, out],
      Sequence @@ FilterRules[{opts}, Options @ Graphics],
      more,
      ImagePadding -> { unit*port, 5*{1, 1} },
      ImageSize -> unit * ($CircuitSize + Total[port])
     ]
   ]

qGateQ::usage = "qGateQ[expr] is True if expr is an expression of operators."

qGateQ[expr_] := Not @ FreeQ[expr, _?QubitQ | "Separator" | "Spacer" ]
(* Recall that FreeQ[ Ket[<|...|>], _?QubitQ] = True . *)


qCircuitGate::usage = "qCircuitGate[expr, opts] preprocesses various circuit elements."

(* NOTE: Do not set Listable attribute for qCircuitGate. *)

Options[ qCircuitGate ] = {
  "TargetFunction"  -> "Rectangle",
  "ControlFunction" -> "Dot",
  "LabelSize" -> 1, (* RELATIVE size *)
  "Label" -> None
 }

(* Gate *)
qCircuitGate[ _QuissoIn | _QuissoOut, opts___?OptionQ ] = Nothing
  
qCircuitGate[ S_?QubitQ, opts___?OptionQ ] :=
  Gate[ Qubits @ S, opts, "Label" -> qGateLabel[S] ]

qCircuitGate[ Measurement[ S_?QubitQ ], opts___?OptionQ ] :=
  Gate[ {S}, "TargetFunction" -> "Measurement", "Label" -> None, opts ]

qCircuitGate[
  HoldPattern @ Projector[v_, qq_, opts___?OptionQ], more___?OptionQ ] :=
  Gate[ qq, "TargetFunction" -> "Projector", "Label" -> None, opts, more ]

qCircuitGate[
  Phase[ ang_, G_?QubitQ, opts___?OptionQ ], more___?OptionQ ] :=
  Gate[ Qubits @ G, opts, more, "Label" -> qGateLabel[ Phase[ang, G] ] ]

qCircuitGate[
  Rotation[ ang_, G_?QubitQ, opts___?OptionQ ], more___?OptionQ ] :=
  Gate[ Qubits @ G, opts, more, "Label" -> qGateLabel[ Rotation[ang, G] ] ]

qCircuitGate[
  EulerRotation[ ang:{_,_,_}, G_?QubitQ, opts___?OptionQ ], more___?OptionQ ] :=
  Gate[ {G}, opts, more, "Label" -> qGateLabel[ EulerRotation[ang, G] ] ]


qCircuitGate[
  ControlledU[ cc:{__?QubitQ}, S_?QubitQ, opts___?OptionQ ],
  more___?OptionQ ] :=
  Gate[ cc, Qubits @ S, opts, more, "Label" -> qGateLabel[S] ]

qCircuitGate[
  ControlledU[
    cc:{__?QubitQ},
    op:(Phase|Rotation|EulerRotation)[j__, optsA___?OptionQ],
    optsB___?OptionQ ],
  optsC___?OptionQ ] :=
  Gate[ cc, Qubits @ op, optsA, optsB, optsC, "Label" -> qGateLabel[op] ]

qCircuitGate[
  ControlledU[ cc:{__?QubitQ}, expr_, opts___?OptionQ ],
  more___?OptionQ ] :=
  Gate[ cc, Qubits[expr], opts, more ] /; Not @ FreeQ[expr, _?QubitQ]


qCircuitGate[ CNOT[cc:{__?QubitQ}, tt:{__?QubitQ}], opts___?OptionQ ] :=
  Gate[ cc, tt, "TargetFunction" -> "CirclePlus" ]

qCircuitGate[ Toffoli[a_?QubitQ, b__?QubitQ, c_?QubitQ], opts___?OptionQ ] :=
  Gate[ {a, b}, {c}, "TargetFunction" -> "CirclePlus" ]

qCircuitGate[ CZ[c_?QubitQ, t_?QubitQ], opts___?OptionQ ] :=
  Gate[ {c}, {t}, "ControlFunction" -> "Dot", "TargetFunction" -> "Dot" ]

qCircuitGate[ SWAP[c_?QubitQ, t_?QubitQ], opts___?OptionQ ] :=
  Gate[ {c}, {t},
    "ControlFunction" -> "Cross",
    "TargetFunction" -> "Cross"
   ]

qCircuitGate[ Fredkin[a_?QubitQ, b_?QubitQ, c_?QubitQ], opts___?OptionQ ] :=
  Gate[ {a}, {b, c},
    "ControlFunction" -> "Dot",
    "TargetFunction" -> "Cross"
   ]


qCircuitGate[
  Oracle[f_, cc:{__?QubitQ}, tt:{__?QubitQ}, opts___?OptionQ],
  more__?OptionQ
 ] := qCircuitGate @ Oracle[f, cc, tt, opts, more]

qCircuitGate @ Oracle[f_, cc:{__?QubitQ}, tt:{__?QubitQ}, opts___?OptionQ] :=
  Gate[ cc, tt, opts,
    "ControlFunction" -> "Oval",
    "TargetFunction" -> "CirclePlus",
    "Label" -> "f" ]


qCircuitGate[
  QuantumFourierTransform[qq:{__?QubitQ}, opts___?OptionQ],
  more__?OptionQ
 ] := qCircuitGate @ QuantumFourierTransform[qq, opts, more]

qCircuitGate[ QuantumFourierTransform[qq:{__?QubitQ}, opts___?OptionQ] ] :=
  Module[
    { more = Join[{opts}, Options @ QuantumFourierTransform],
      lbl, ang },
    { lbl, ang } = {"Label", "LabelRotation"} /. more;
    Gate[qq, "Label" -> Rotate[lbl, ang], Sequence @@ more]
   ]

qCircuitGate[
  HoldPattern @
    Dagger @ QuantumFourierTransform[qq:{__?QubitQ}, opts___?OptionQ],
  more__?OptionQ
 ] := qCircuitGate @ Dagger @ QuantumFourierTransform[qq, opts, more]

qCircuitGate[
  HoldPattern @
    Dagger @ QuantumFourierTransform[qq:{__?QubitQ}, opts___?OptionQ]
 ] := Module[
   { more = Join[{opts}, Options @ QuantumFourierTransform],
     lbl, ang },
   { lbl, ang } = {"Label", "LabelRotation"} /. more;
   Gate[qq, "Label" -> Rotate[SuperDagger[lbl], ang], Sequence @@ more]
  ]


qCircuitGate[ expr:Except[_List|_?(FreeQ[#,_?QubitQ]&)], opts___?OptionQ ] :=
  Gate[ Qubits @ expr, opts ]

qCircuitGate[ z_?NumericQ, opts___?OptinQ ] := "Spacer"

qCircuitGate[ gate:("Separator" | "Spacer"), opts___?OptinQ ] := gate


qCircuitGate[ expr_, opts___?OptinQ ] := expr /; FreeQ[expr, _?QubitQ]
(* Graphics primitives corresponds to this case. *)

qCircuitGate[ a_List, opts___?OptionQ ] :=
  qCircuitGate @@ Join[ a, {opts} ]

qCircuitGate[ a_, b__, opts___?OptionQ ] := Map[
  qCircuitGate[#, opts]&,
  {a, b}
 ]


qGateLabel::usage = "qGateLabel[G] returns the label of the circuit element to be displayed in the circuit diagram."

qGateLabel[ S_?QubitQ ] := Last[S] /. {
  0 -> "I",
  1 -> "X", 2 -> "Y", 3 -> "Z",
  6 -> "H", 7 -> "S", 8 -> "T" }

qGateLabel[ gate_Phase ] := "\[CapitalPhi]"

qGateLabel[ Rotation[_, S_?QubitQ, ___] ] :=
  Subscript[ "U", FlavorLast[S] /. {1->"x", 2->"y", 3->"z"} ]

qGateLabel[ EulerRotation[{_, _, _}, S_?QubitQ, ___] ] := Subscript["U", "E"]


qDrawGateCirclePlus[ x_, yy_List, ___ ] :=
  qDrawGateCirclePlus @@@ Thread @ {x, yy}

qDrawGateCirclePlus[ x_, y_?NumericQ, ___ ] := Module[
  { circ, crss },
  circ = Circle[ {x, y}, $GateSize / 3 ];
  crss = Line[ {
      { {x-$GateSize/3,y}, {x+$GateSize/3,y} },
      { {x,y-$GateSize/3}, {x,y+$GateSize/3} }
     } ];
  { circ, crss }
 ]


qDrawGateCross[x_, yy_List, ___] := qDrawGateCross @@@ Thread @ {x, yy}

qDrawGateCross[x_, y_, ___] := List @ Line[{
    { {x,y}+{-1,-1}$DotSize, {x,y}+{+1,+1}$DotSize },
    { {x,y}+{-1,+1}$DotSize, {x,y}+{+1,-1}$DotSize }
   }]


qDrawGateMeasurement[ x_, {y_}, ___] := qDrawGateMeasurement[x, y]

qDrawGateMeasurement[ x_, y_, ___ ] := Module[
  { arc, needle },
  pane = qDrawGateRectangle[x, y];
  arc = Circle[ {x, y - 0.25 $GateSize}, .5 $GateSize, {1,5} Pi/6 ];
  needle = Line[{ {x, y - 0.25 $GateSize}, {x,y} + .3{1,1}$GateSize }];
  { pane, arc, needle }
 ]


qDrawGateProjector[ x_, yy_List, ___ ] := Module[
  { y1 = Min @ yy,
    y2 = Max @ yy,
    pane, symb },
  pane = Polygon[{
      {x, y2} + $GateSize {+1,+1}/2,
      {x, y2} + $GateSize {-1,+1}/2,
      {x, y1} + $GateSize {-1,-1}/2,
      {x, y1} + $GateSize {+1,-1}/2 }];
  symb = Polygon[{
      {x, y2} + $GateSize {+1,+1}/2,
      {x, y1} + $GateSize {-1,-1}/2,
      {x, y2} + $GateSize {-1,+1}/2,
      {x, y1} + $GateSize {+1,-1}/2 }];
  { White, EdgeForm[], pane, EdgeForm[Black], White, symb }
 ]


qDrawGateDot[ x_, yy_List, ___ ] := qDrawGateDot @@@ Thread @ {x, yy}

qDrawGateDot[ x_, y_?NumericQ, ___ ] := Disk[ {x, y}, $DotSize ]

qDrawGateRectangle[ x_, yy_List, opts___?OptionQ ] := Module[
  { y1 = Min @ yy,
    y2 = Max @ yy,
    pane, text },
  text = qGateText[x, Mean @ {y1, y2}, opts];
  pane = Rectangle[
    {x, y1} - 0.5{1,1}$GateSize,
    {x, y2} + 0.5{1,1}$GateSize ];
  { {EdgeForm[Black], White, pane}, text }
 ]

qDrawGateRectangle[ x_, y_?NumericQ, opts___?OptionQ ] :=
  qDrawGateRectangle[x, {y}, opts]


qDrawGateOval[ x_, y_?NumericQ, opts___?OptionQ ] := Module[
  { pane, text},
  text = qGateText[x, y, opts];
  pane = Disk[{x, y}, $GateSize/2];
  { {EdgeForm[Black], White, pane}, text }
 ]

qDrawGateOval[ x_, yy_List, opts___?OptionQ ] := Module[
  { x1 = x - $GateSize/2,
    x2 = x + $GateSize/2,
    y1 = Min @ yy,
    y2 = Max @ yy,
    y0, y3, ff, pane, text},
  
  text = qGateText[x, Mean @ {y1, y2}, opts];

  ff = 0.657;
  y0 = y1 - $GateSize ff;
  y3 = y2 + $GateSize ff;
  pane = FilledCurve @ {
    BezierCurve @ {{x2, y2}, {x2, y3}, {x1, y3}, {x1, y2}}, 
    Line @ {{x1, y2}, {x1, y1}}, 
    BezierCurve @ {{x1, y0}, {x2, y0}, {x2, y1}}
   };
  { {EdgeForm[Black], White, pane}, text }
 ]


qGateText[ x_, y_, opts___?OptionQ ] := Module[
  { label, factor },
  { label, factor } = { "Label", "LabelSize" } /. {opts} /.
      Options[qCircuitGate];
  If[ label == None, Return @ Nothing ];
  Text[
    Style[ label, Italic,
      FontWeight -> "Light",
      FontSize   -> Scaled[(0.5 $GateSize / $CircuitSize) factor] ],
    {x, y},
    {0, 0}
    (* Notice the y-offset:
       Before v12.2, y-offset=0 shifted a bit upward.
       It seems different in v12.2. *)
   ]
 ]


SetAttributes[qDrawGateSymbol, Listable]

qDrawGateSymbol[name_?StringQ] :=
  Symbol["Q3`Circuit`" <> "qDrawGate" <> name] /;
  MemberQ[
    { "Dot", "CirclePlus", "Projector", "Measurement",
      "Rectangle", "Oval", "Cross" },
    name
   ]

qDrawGateSymbol[name_?StringQ] := (
  Message[QuantumCircuit::nofunc, name];
  qDrawGateSymbol["Rectangle"]
 )


qCircuitNodes::usage = "qCircuitNodes[ ... ] takes circuit elements and construct them as nodes of the circuit diagram by assigning horizontal and vertical coordinates to them."

qCircuitNodes[ gg_List, xx_List, yy_Association ] := Module[
  { ff, F },
  
  ff = Thread[ F[ gg, xx, yy ] ];
  ff = ff /. { F -> qDrawGate };

  Return[ff];
 ]

qDrawGate::uage = "Renders the gates."

qDrawGate[ gg_List, x_, yy_Association ] := Map[ qDrawGate[#, x, yy]&, gg ]

qDrawGate[
  Gate[cc:{__?QubitQ}, tt:{__?QubitQ}, opts___?OptionQ],
  x_, yy_Association
 ] := Module[
   { yc = Lookup[yy, cc],
     yt = Lookup[yy, tt],
     control, target, dots, link, pane },

   { control, target } = qDrawGateSymbol[
     { "ControlFunction", "TargetFunction" } /. {opts} /.
       Options[qCircuitGate]
    ];
   
   link = Line @ Join[ Thread @ {x, yc}, Thread @ {x, yt} ];
   
   dots = control[x, yc, opts];
   pane = target[x, yt, opts];
   
   Join[{link}, dots, pane]
  ]


qDrawGate[
  Gate[tt:{__?QubitQ}, opts___?OptionQ],
  x_, yy_Association
 ] := Module[
   { yt = Lookup[yy, tt],
     target },
   target = qDrawGateSymbol[
     "TargetFunction" /. {opts} /. Options[qCircuitGate]
    ];

   target[x, yt, opts]
  ]


qDrawGate[ "Spacer", _, _Association ] = Nothing

qDrawGate[ "Separator", x_, yy_Association ] := Module[
  { xy = Tuples[{{x}, MinMax @ yy }] },
  { Dotted,
    Line @ {
      {0,-$CircuitUnit/2} + First @ xy,
      {0,+$CircuitUnit/2} + Last @ xy }
   }
 ]

qDrawGate[ g_, x_, yy_Association ] := g


qCircuitLines::usage = "qCircuitLines[gg, x, y] finds when Measurement occurs in the QuantumCircuit and renders the qubit line after Measurement in dashes."

qCircuitLines[ gg_List, xx_List, yy_Association ] := Module[
  { mm, zz, dashed, plain },
  mm = Map[
    Cases[{#}, Gate[{S_?QubitQ}, "TargetFunction" -> "Measurement", ___?OptionQ] -> S, Infinity]&,
    gg
   ];
  mm = Flatten[ Thread /@ Thread[mm -> xx] ];
  mm = KeySort @ KeyTake[Association @ mm, Keys @ yy];
  
  zz = Lookup[yy, Keys @ mm];
  dashed = Line @ Transpose @ {
    Thread[ {Values @ mm, zz} ],
    Thread[ {1+Max[xx], zz} ] };

  plain = Association @ Thread[ Keys[yy] -> 1+Max[xx] ];
  plain = Join[ plain, mm ];
  plain = Line @ Transpose @ {
    Thread[{0, Values @ yy}],
    Transpose @ {Values @ plain, Values @ yy} };

  {{Dashed, dashed}, plain}
 ]


qCircuitOutput::usage = "It draws the output states behind the scene."

qCircuitOutput[ Missing["NotFound"], xx_List, yy_Association ] = {}

qCircuitOutput[ gg:{___}, xx_List, yy_Association ] := Module[
  { xy = Map[{$CircuitSize + $InOutOffset, #}&, yy],
    ff = List @ qCircuitPort @ gg },
  Map[ qDrawPort[#, xy]&, ff ]
 ]


qCircuitInput::usage = "It draws the input states behind the scene."

qCircuitInput[ Missing["NotFound"], xx_List, yy_Association ] = {}

qCircuitInput[ gg:{___}, xx_List, yy_Association ] := Module[
  { xy = Map[{-$InOutOffset, #}&, yy],
    ff },
  
  (* ff = Join[ff, {"Pivot" -> {1,0}, "Type" -> -1} ]; *)
  ff = Join[gg, {"Pivot" -> {1, 0}, "Type" -> -1} ];
  ff = List @ qCircuitPort @ ff;

  Map[ qDrawPort[#, xy]&, ff ]
 ]


qCircuitPort::usage = "qCircuitPorts preprocesses various input and output forms of QuantumCircuit."

Options[ qCircuitPort ] = {
  "Label" -> Automatic,
  "LabelSize" -> 1, (* RELATIVE *)
  "Pivot" -> {-1, 0},
  "Type"  -> 1 (* 1: input, -1: output *)
 }

qCircuitPort[ v_Ket, opts___?OptionQ ] := Port[v, opts]

qCircuitPort[ v_ProductState, opts___?OptionQ ] := Port[v, opts]

qCircuitPort[ expr:Except[_List], opts___?OptionQ ] :=
  Port[expr, opts] /; Not @ FreeQ[expr, _Ket]

qCircuitPort[ a_List, opts___?OptionQ ] := qCircuitPort @@ Join[a, {opts}]

qCircuitPort[ g_, opts___?OptionQ ] := g /; FreeQ[g, _Ket | _ProductState]

qCircuitPort[ a_, b__, opts___?OptionQ ] :=
  Map[ qCircuitPort[#, opts]&, {a, b} ]


qDrawPort::usage = "qDrawPort renders the input/output ports."

qDrawPort[ gg_List, xy_Association ] := Map[ qDrawPort[#, xy]&, gg ]

qDrawPort[ Port[ Ket[v_], opts___?OptionQ ], xy_Association ] := Module[
  { vv = Ket /@ v,
    tt, label, pivot },
  { label, pivot } = {"Label", "Pivot"} /. {opts} /. Options[qCircuitPort];

  If[ label === None, Return @ {} ];
  
  tt = If [ label === Automatic,
    vv,
    If[ Not @ ListQ @ label, label = {label} ];
    AssociationThread[ Keys[v] -> PadRight[label, Length[v], label] ]
   ];
  
  Values @ MapThread[
    qPortText[#1, #2, pivot, opts]&,
    KeyIntersection @ {tt, xy}
   ]
 ]

qDrawPort[
  Port[ ProductState[v_Association, opts___], more___?OptionQ ],
  xy_Association
 ] := Module[
   { label, pivot, tt },
   { label, pivot } = {"Label", "Pivot"} /. {opts, more} /.
     Options[qCircuitPort];

   tt = If [ label === Automatic,
     Map[ Simplify @ Dot[{Ket[0], Ket[1]}, #]&, v ],
     If[ Not @ ListQ @ label, label = {label} ];
     AssociationThread[ Keys[v] -> PadRight[label, Length[v], label] ]
    ];
   
   Values @ MapThread[
     qPortText[#1, #2, pivot, opts, more]&,
     KeyIntersection @ {tt, xy}
    ]
  ]

qDrawPort[ Port[ expr_, opts___?OptionQ ], xy_Association ] := (
  Message[QuantumCircuit::noqubit, expr];
  Return @ {};
 ) /; Qubits[expr] == {}

qDrawPort[ Port[ expr_, opts___?OptionQ ], xy_Association ] := Module[
  { qq = Qubits @ expr,
    label, pivot, dir, brace, text, zz },

  { label, pivot, dir } = { "Label", "Pivot", "Type" } /.
    {opts} /. Options[qCircuitPort];

  If[ label === None, Return @ {} ];
  
  text = If[label === Automatic, SimpleForm[expr, qq], label];
  
  zz = Transpose[ MinMax /@ Transpose @ Lookup[xy, qq] ];

  If[ Length[qq] > 1,
    brace = qPortBrace[dir, zz];
    zz = Mean @ zz + ($InOutOffset + $BraceWidth) {dir, 0};
    { brace, qPortText[text, zz, pivot, opts] },
    qPortText[text, Mean @ zz, pivot, opts]
   ]
 ]

qDrawPort[ g_, xy_Association ] := g


qPortText[text_, pt:{_, _}, pivot:{_, _}, opts___?OptionQ] := Module[
  { factor },
  factor = "LabelSize" /. {opts} /. Options[qCircuitPort];
  Text[
    Style[
      text,
      FontWeight -> "Light",
      FontSize -> Scaled[(0.4 $GateSize / $CircuitSize) factor]
     ],
    pt, pivot
   ]
 ]


qPortBrace[ dir:(-1|1), { a:{_, _}, b:{_, _} } ] :=
  Line[{ a, a + $BraceWidth {dir, 0}, b + $BraceWidth {dir, 0}, b }]

End[] (* `Circuit`*)


Begin["`Qudit`"]

$symb = Unprotect[Missing]

Qudit::usage = "Qudit represents a multidimensional system."

Qudit::range = "The quantum level specification s should be within the range 0 \[LessEqual] s < d, where the dimension d = `` for ``."

Options[Qudit] = { Dimension -> 3 }

Qudit /:
Let[Qudit, {ls__Symbol}, opts___?OptionQ] := Module[
  { dim },
  dim = Dimension /. {opts} /. Options[Qudit];

  Let[NonCommutative, {ls}];
    
  Scan[ setQudit[#, dim]&, {ls} ];
 ]

setQudit[x_Symbol, dim_Integer] := (
  QuditQ[x] ^= True;
  QuditQ[x[___]] ^= True;

  Kind[x] ^= Qudit;
  Kind[x[___]] ^= Qudit;
  
  Dimension[x] ^= dim;
  Dimension[x[___]] ^= dim;

  LogicalValues[x] ^= Range[0, dim-1];
  LogicalValues[x[___]] ^= Range[0, dim-1];

  x /: Power[x, n_Integer] := MultiplyPower[x, n];
  x /: Power[x[j___], n_Integer] := MultiplyPower[x[j], n];

  x[j___, ij:Rule[_List, _]] := x[j, Thread @ ij];
  x[j___, ij:Rule[_, _List]] := x[j, Thread @ ij];
  
  x[j___, All] := x[j, Rule @@@ Tuples[Range[0, dim-1], 2]];
  
  x[j___, Null] := x[j, None];
  
  x[j___, None, k_] := x[j, k];
  (* In particular, x[j, None, None] = x[j, None]. *)

  x /: Dagger[ x[j___, Rule[a_Integer, b_Integer]] ] := x[j, Rule[b,a]];

  x[j___, Rule[a_Integer, b_Integer]] := (
    Message[Qudit::range, dim, x[j,None]];
    0
   ) /; Or[ a < 0, a >= Dimension[x], b < 0, b >= Dimension[x] ];

  Format[ x[j___, None] ] := DisplayForm @ SpeciesBox[x, {j}, {}];  
  Format[ x[j___, 0] ] := DisplayForm @ SpeciesBox[1, {j}, {0}];  
  Format[ x[j___, a_->b_] ] :=
    DisplayForm @ SpeciesBox[ RowBox @ {"(",Ket[b],Bra[a],")"}, {j}, {}];  
 )

QuditQ[_] = False

Missing["KeyAbsent", _Symbol?QuditQ[___, None]] := 0


Qudits::usage = "Qudits[expr] gives the list of all qudits appearing in expr."

Qudits[ expr_ ] := FlavorNone @ Union @ Map[Most] @
  Cases[ Normal[{expr}, Association], _?QuditQ, Infinity ]
(* NOTE: { } are necessary around expr; otherwise, Qudits[S[1,2]] does
   not give the trivial result. *)


(* MultiplyDegree for operators *)
MultiplyDegree[_?QuditQ] = 1


Dyad[a_Association, b_Association, {A_?QuditQ}] := A[b[A] -> a[A]]
(* For a single Qudit, Dyad is meaningless. *)

(* Base: See Cauchy *)

Base[ S_?QuditQ[j___, _] ] := S[j]
(* For Qudits, the final Flavor index is special. *)


(* FlavorNone: See Cauchy *)

FlavorNone[S_?QuditQ] := S[None]

FlavorNone[S_?QuditQ -> m_] := S[None] -> m


(* FlavorMute: See Cauchy *)

FlavorMute[S_Symbol?QuditQ] := S[None]

FlavorMute[S_Symbol?QuditQ[j___, _]] := S[j, None]

FlavorMute[S_Symbol?QuditQ[j___, _] -> m_] := S[j, None] -> m


(**** <Ket for Qudits> ****)

(*
KetRule[ r:Rule[_?QuditQ, _] ] := FlavorNone[r]

KetRule[ r:Rule[{__?QuditQ}, _] ] := FlavorNone @ Thread[r]
 *)

KetTrim[_?QuditQ, 0] = Nothing

KetTrim[A_?QuditQ, s_Integer] := (
  Message[Qudit::range, Dimension[A], FlavorNone @ A];
  Nothing
 ) /; s >= Dimension[A]

(**** </Ket for Qubits> ****)


(* Qudit on Ket *)

HoldPattern @
  Multiply[a___, S_?QuditQ[j___, Rule[x_,y_]], v:Ket[_Association], b___] :=
  Multiply[a, v[S[j,None] -> y], b] /; v[S[j,None]] == x
(* TODO: handle symbolic flavors x*)

HoldPattern @
  Multiply[a___, S_?QuditQ[j___, Rule[x_,y_]], v:Ket[_Association], b___] :=
  0 /; v[S[j,None]] != x
(* TODO: handle symbolic flavors x*)


(* Qudit Operator Algebra *)

HoldPattern @ Multiply[pre___, _?QuditQ[___, 0], post___] :=
  Multiply[pre, post]

HoldPattern @ Multiply[pre___,
  A_Symbol?QuditQ[j___, y_->z_], A_Symbol?QuditQ[j___, x_->y_],
  post___] := Multiply[pre, A[j, x->z], post]

HoldPattern @ Multiply[pre___,
  A_Symbol?QuditQ[j___, z_->w_], A_Symbol?QuditQ[j___, x_->y_],
  post___] := Multiply[pre, A[j, x->w], post] KroneckerDelta[y, z]

HoldPattern @ Multiply[pre___, A_?QuditQ, B_?QuditQ, post___] :=
  Multiply[pre, B, A, post] /; Not @ OrderedQ @ {A, B}


Once[ $GarnerTests = Join[$GarnerTests, {QuditQ}]; ]


(**** <Basis> ****)

Basis[ S_?QuditQ ] :=
  Ket /@ Thread[FlavorNone[S] -> Range[0, Dimension[S]-1]]

(**** </Basis> ****)


TheQuditKet::usage = "TheQuditKet[{j,m}] returns the (m+1)th unit column vector in the j-dimensional complex vector space.\nTheQuditKet[{j1,m1}, {j2,m2}, ...] returns the direct product of vectors.\nTheQuditKet[j, {m1, m2, ...}] is equivalent to TheQuditKet[{j,m1}, {j,m2}, ...]."

TheQuditKet[ {dim_Integer, m_Integer} ] :=
  SparseArray[{(m+1) -> 1}, dim] /; 0 <= m < dim

TheQuditKet[ dim_Integer, mm:{__Integer} ] :=
  TheQuditKet @@ Thread @ {dim, mm}

TheQuditKet[ cc:{_Integer, _Integer}.. ] := Module[
  { aa = Transpose @ {cc},
    dd, pwrs, bits, p},
  dd = First @ aa;
  pwrs = Reverse @ FoldList[ Times, 1, Reverse @ Rest @ dd ];
  bits = Last @ aa;
  p = 1 + bits.pwrs;
  SparseArray[ {p -> 1}, Times @@ dd ]
 ]


(**** <Parity> ****)

Parity[A_?QuditQ] := Module[
  { jj = Range[0, Dimension[A]-1],
    op },
  op = A /@ Thread[jj->jj];
  Power[-1, jj] . op
 ]


ParityEvenQ[v_Ket, a_?QuditQ] := EvenQ @ v @ a

ParityOddQ[v_Ket, a_?QuditQ] := OddQ @ v @ a

(**** </Parity> ****)


(**** <Matrix for Qudits> ****)

TheMatrix[ S_?QuditQ[___, i_ -> j_] ] :=
  SparseArray[ {1+j,1+i} -> 1, Dimension[S] {1, 1} ]

TheMatrix[ Ket[ Association[ S_?QuditQ -> n_Integer] ] ] := SparseArray[
  If[ 0 <= n < Dimension[S], n+1 -> 1, {}, {} ],
  Dimension[S]
 ]

(**** </Matrix> *****)


QuditExpression::usage = "QuditExpression is obsolete now. Use ExpressionFor instead."

QuditExpression[args___] := (
  Message[Q3`Q3General::obsolete, "QuditExpression", "ExpressionFor"];
  ExpressionFor[args]
 )


ReplaceByFourier[old_?QuditQ -> new_?QuditQ, opts___?OptionQ] := Module[
  { mm = FourierMatrix[Dimension @ old, opts],
    ij = Range[0, Dimension[old]-1],
    aa, bb },  
  aa = old[All];
  bb = Outer[new[#1 -> #2]&, ij, ij];
  bb = Flatten[ Topple[mm] . bb . mm ];
  Thread[aa -> bb]
 ]

ReplaceByFourier[
  a:Rule[_?QuditQ, _?QuditQ],
  b:Rule[_?QuditQ, _?QuditQ]..,
  opts___?OptionQ] := Map[ ReplaceByFourier[#, opts]&, {a, b} ]

ReplaceByFourier[expr_, old_?QuditQ -> new_?QuditQ, opts___?OptionQ] :=
  Garner[ expr /. ReplaceByFourier[old -> new, opts] ]


Protect[Evaluate @ $symb]

End[] (* `Qudit` *)


EndPackage[]
