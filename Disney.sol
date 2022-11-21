// SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 <0.7.0;
pragma experimental ABIEncoderV2;
import "./ERC20.sol";

contract Disney {

    // -------------------------------DECLARACIONES INICIALES-------------------

    // Instancia del contrato token
    ERC20Basic private token;

    // Declaración dirección de Disney (owner)
    address payable public owner;

    // Constructor
    constructor () public {

        token = new ERC20Basic(2000000);
        
        owner = msg.sender;

    }

    // Estructura de datos para almacenar a los clientes de Disney
    // Podemos almacenar algún otro dato del cliente (lo que sea)
    struct cliente {
        uint tokens_comprados;
        string [] atracciones_disfrutadas;
    }

    // Mapping para el registro de clientes
    mapping (address => cliente) public Clientes;


    // -------------------------------GESTIÓN DE TOKENS-------------------

    // Función para establecer el precio de un Token
    function PrecioTokens(uint _numTokens) internal pure returns (uint) {
        // Conversión de Tokens a Ethers: 1 Token -> 1 Ether
        return _numTokens*(1 ether);
    }

    // Función para comprar Tokens en Disney y disfrutar de las atracciones
    // Usando modificador de función payable
    function CompraTokens(uint _numTokens) public payable {
        // Establecer el precio de los Tokens
        uint coste = PrecioTokens(_numTokens);
        // Se evalúa el dinero que el cliente paga con los Tokens
        require (msg.value >= coste, "Compra menos Tokens o paga con más ethers.");
        // Diferencia de lo que el cliente paga
        uint returnValue = msg.value - coste;
        // Disney retorna la cantidad de ethers al cliente
        msg.sender.transfer(returnValue);
        // Obtención del número de tokens disponibles
        uint Balance = balanceOf();
        require(_numTokens <= Balance, "Compra un número menor de Tokens.");
        // Se transfiere el número de Tokens al cliente
        token.transfer(msg.sender, _numTokens);
        // Registro de tokens comprados
        Clientes[msg.sender].tokens_comprados += _numTokens;

    }

    // Balance de Tokens del contrato Disney
    function balanceOf() public view returns (uint) {
        return token.balanceOf(address(this));
    }

    // Visualizar el número de tokens restantes de un Cliente
    function MisTokens()public view returns (uint) {
        return token.balanceOf(msg.sender);
    }

    // Funcion para generar más tokens
    function GeneraTokens(uint _numTokens) public Unicamente(msg.sender) {
        token.increaseTotalSupply(_numTokens);
    }

    // Modificador para controlar las funciones ejecutables por Disney
    modifier Unicamente(address _direccion) {
        require(_direccion == owner, "No tienes permisos para ejecutar esta función.");
        _;
    }

    // -------------------------------GESTIÓN DE DISNEY-------------------

    // Eventos
    event disfuta_atraccion(string);
    event nueva_atraccion(string, uint);
    event baja_atraccion(string);

    // Estructura de datos de la atracción
    struct atraccion {
        string nombre_atraccion;
        uint precio_atraccion;
        bool estado_atraccion;
    }

    // Mapping para relacionar un nombre de una atracción con 
    // una estructura de datos de la atracción
    mapping (string => atraccion) public MappingAtracciones;

    // Array para almacenar el nombre de las atracciones
    string [] Atracciones;

    // Mapping para relacionar una identidad (cliente) con su historial en DISNEY
    mapping (address => string []) HistorialAtracciones;

    // Atracciones
    // Star Wars -> 2 Tokens
    // Toy Story -> 5 Tokens
    // Piratas del caribe -> 8 Tokens

    // Crear nuevas atracciones para Disney (SOLO es ejecutable por Disney)
    // gracias al modificador "Unicamente"
    function NuevaAtraccion(string memory _nombreAtraccion, uint _precio) public Unicamente(msg.sender) {
        // Creacion de una atracción en Disney
        MappingAtracciones[_nombreAtraccion] = atraccion(_nombreAtraccion, _precio, true);
        // Almacenar en un array el nombre de la atracción
        Atracciones.push(_nombreAtraccion);
        // Emisión del evento para la nueva atracción
        emit nueva_atraccion(_nombreAtraccion, _precio);
    }









}