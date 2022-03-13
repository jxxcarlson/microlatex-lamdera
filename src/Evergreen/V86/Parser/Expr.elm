module Evergreen.V86.Parser.Expr exposing (..)

import Evergreen.V86.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V86.Parser.Meta.Meta
    | Text String Evergreen.V86.Parser.Meta.Meta
    | Verbatim String String Evergreen.V86.Parser.Meta.Meta
