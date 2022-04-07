module Evergreen.V280.Parser.Expr exposing (..)

import Evergreen.V280.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V280.Parser.Meta.Meta
    | Text String Evergreen.V280.Parser.Meta.Meta
    | Verbatim String String Evergreen.V280.Parser.Meta.Meta
