# Gelato
## A scheme-ish Lisp interpreter and compiler to GDScript

Currently very WIP. The interpreter supports GDScript's +, -, /, *, and ** ops, as well as every @Global and @GDScript builtin function.

Dot identifiers can be used, along with constructors. For example:
```scheme
(.darkened (Color "BLUE") 0.2)
```
is equivalent to: 
```gdscript
Color("BLUE").darkened(0.2)
```

Another example:
```scheme
(.normalized (+ Vector3.UP Vector3.LEFT))
```
is equivalent to:
```gdscript
(Vector3.UP + Vector3.LEFT).noramlized()
```

Binding is not implemented. Compiler is not implemented.
