module Evergreen.V713.Parser.Expr exposing (..)

import Evergreen.V713.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V713.Parser.Meta.Meta
    | Text String Evergreen.V713.Parser.Meta.Meta
    | Verbatim String String Evergreen.V713.Parser.Meta.Meta
