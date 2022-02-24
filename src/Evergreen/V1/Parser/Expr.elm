module Evergreen.V1.Parser.Expr exposing (..)

import Evergreen.V1.Parser.Token


type Expr
    = Expr String (List Expr) Evergreen.V1.Parser.Token.Meta
    | Text String Evergreen.V1.Parser.Token.Meta
    | Verbatim String String Evergreen.V1.Parser.Token.Meta
    | Error String
