module Evergreen.V369.Parser.Expr exposing (..)

import Evergreen.V369.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V369.Parser.Meta.Meta
    | Text String Evergreen.V369.Parser.Meta.Meta
    | Verbatim String String Evergreen.V369.Parser.Meta.Meta
