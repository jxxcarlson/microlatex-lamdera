module Evergreen.V337.Parser.Expr exposing (..)

import Evergreen.V337.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V337.Parser.Meta.Meta
    | Text String Evergreen.V337.Parser.Meta.Meta
    | Verbatim String String Evergreen.V337.Parser.Meta.Meta
