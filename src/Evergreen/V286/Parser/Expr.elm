module Evergreen.V286.Parser.Expr exposing (..)

import Evergreen.V286.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V286.Parser.Meta.Meta
    | Text String Evergreen.V286.Parser.Meta.Meta
    | Verbatim String String Evergreen.V286.Parser.Meta.Meta
