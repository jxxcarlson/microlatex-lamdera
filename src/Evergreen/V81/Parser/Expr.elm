module Evergreen.V81.Parser.Expr exposing (..)

import Evergreen.V81.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V81.Parser.Meta.Meta
    | Text String Evergreen.V81.Parser.Meta.Meta
    | Verbatim String String Evergreen.V81.Parser.Meta.Meta
