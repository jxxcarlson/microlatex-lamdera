module Evergreen.V149.Parser.Expr exposing (..)

import Evergreen.V149.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V149.Parser.Meta.Meta
    | Text String Evergreen.V149.Parser.Meta.Meta
    | Verbatim String String Evergreen.V149.Parser.Meta.Meta
