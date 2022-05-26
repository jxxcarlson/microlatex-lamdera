module Evergreen.V526.Parser.Expr exposing (..)

import Evergreen.V526.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V526.Parser.Meta.Meta
    | Text String Evergreen.V526.Parser.Meta.Meta
    | Verbatim String String Evergreen.V526.Parser.Meta.Meta
