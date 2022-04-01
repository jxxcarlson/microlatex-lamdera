module Evergreen.V193.Parser.Expr exposing (..)

import Evergreen.V193.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V193.Parser.Meta.Meta
    | Text String Evergreen.V193.Parser.Meta.Meta
    | Verbatim String String Evergreen.V193.Parser.Meta.Meta
