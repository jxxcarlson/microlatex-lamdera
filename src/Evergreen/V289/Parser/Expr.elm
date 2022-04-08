module Evergreen.V289.Parser.Expr exposing (..)

import Evergreen.V289.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V289.Parser.Meta.Meta
    | Text String Evergreen.V289.Parser.Meta.Meta
    | Verbatim String String Evergreen.V289.Parser.Meta.Meta
