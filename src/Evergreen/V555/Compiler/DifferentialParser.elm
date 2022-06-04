module Evergreen.V555.Compiler.DifferentialParser exposing (..)

import Evergreen.V555.Compiler.AbstractDifferentialParser
import Evergreen.V555.Compiler.Acc
import Evergreen.V555.Parser.Block
import Evergreen.V555.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V555.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V555.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V555.Parser.Block.ExpressionBlock) Evergreen.V555.Compiler.Acc.Accumulator
