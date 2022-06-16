module Evergreen.V650.Compiler.DifferentialParser exposing (..)

import Evergreen.V650.Compiler.AbstractDifferentialParser
import Evergreen.V650.Compiler.Acc
import Evergreen.V650.Parser.Block
import Evergreen.V650.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V650.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V650.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V650.Parser.Block.ExpressionBlock) Evergreen.V650.Compiler.Acc.Accumulator
