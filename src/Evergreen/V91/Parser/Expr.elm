module Evergreen.V91.Parser.Expr exposing (..)

import Evergreen.V91.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V91.Parser.Meta.Meta
    | Text String Evergreen.V91.Parser.Meta.Meta
    | Verbatim String String Evergreen.V91.Parser.Meta.Meta
