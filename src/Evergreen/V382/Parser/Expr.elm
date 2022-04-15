module Evergreen.V382.Parser.Expr exposing (..)

import Evergreen.V382.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V382.Parser.Meta.Meta
    | Text String Evergreen.V382.Parser.Meta.Meta
    | Verbatim String String Evergreen.V382.Parser.Meta.Meta
