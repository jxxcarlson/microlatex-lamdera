module Evergreen.V288.Parser.Expr exposing (..)

import Evergreen.V288.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V288.Parser.Meta.Meta
    | Text String Evergreen.V288.Parser.Meta.Meta
    | Verbatim String String Evergreen.V288.Parser.Meta.Meta
