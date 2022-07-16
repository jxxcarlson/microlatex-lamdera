module Evergreen.V704.Parser.Expr exposing (..)

import Evergreen.V704.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V704.Parser.Meta.Meta
    | Text String Evergreen.V704.Parser.Meta.Meta
    | Verbatim String String Evergreen.V704.Parser.Meta.Meta
