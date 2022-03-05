module Evergreen.V65.Parser.Expr exposing (..)

import Evergreen.V65.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V65.Parser.Meta.Meta
    | Text String Evergreen.V65.Parser.Meta.Meta
    | Verbatim String String Evergreen.V65.Parser.Meta.Meta
    | Error String
