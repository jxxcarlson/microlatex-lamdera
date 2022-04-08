module Chat exposing (getClients, initialGroup, insert)

import Dict
import Lamdera
import Types


getClients : Types.Username -> Types.ConnectionDict -> List Lamdera.ClientId
getClients username dict =
    Dict.get username dict |> Maybe.map (List.map .client) |> Maybe.withDefault []


insert : Types.ChatMessage -> Types.ChatDict -> Types.ChatDict
insert message chatDict =
    case Dict.get message.group chatDict of
        Nothing ->
            Dict.insert message.group [ message ] chatDict

        Just messages ->
            Dict.insert message.group (message :: messages) chatDict


initialGroup : Types.ChatGroup
initialGroup =
    { name = "test"
    , members = [ "jxxcarlson", "mario", "aristotle" ]
    , owner = "jxxcarlson"
    , assistant = Nothing
    }
