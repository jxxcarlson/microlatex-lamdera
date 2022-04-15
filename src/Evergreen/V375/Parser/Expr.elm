module Evergreen.V375.Parser.Expr exposing (..)

import Evergreen.V375.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V375.Parser.Meta.Meta
    | Text String Evergreen.V375.Parser.Meta.Meta
    | Verbatim String String Evergreen.V375.Parser.Meta.Meta
