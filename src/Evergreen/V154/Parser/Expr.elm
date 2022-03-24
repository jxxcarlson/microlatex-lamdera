module Evergreen.V154.Parser.Expr exposing (..)

import Evergreen.V154.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V154.Parser.Meta.Meta
    | Text String Evergreen.V154.Parser.Meta.Meta
    | Verbatim String String Evergreen.V154.Parser.Meta.Meta
