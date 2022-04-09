module Evergreen.V310.Authentication exposing (..)

import Dict
import Evergreen.V310.Credentials
import Evergreen.V310.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V310.User.User
    , credentials : Evergreen.V310.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
