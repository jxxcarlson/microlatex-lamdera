module Evergreen.V351.Parser.Expr exposing (..)

import Evergreen.V351.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V351.Parser.Meta.Meta
    | Text String Evergreen.V351.Parser.Meta.Meta
    | Verbatim String String Evergreen.V351.Parser.Meta.Meta
