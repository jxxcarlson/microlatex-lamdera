module Evergreen.V515.Parser.Expr exposing (..)

import Evergreen.V515.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V515.Parser.Meta.Meta
    | Text String Evergreen.V515.Parser.Meta.Meta
    | Verbatim String String Evergreen.V515.Parser.Meta.Meta
