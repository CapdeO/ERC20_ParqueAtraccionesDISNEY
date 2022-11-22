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
    event disfuta_atraccion(string, uint, address);
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

    // Dar de baja a las atracciones en Disney
    function BajaAtraccion (string memory _nombreAtraccion) public Unicamente(msg.sender) {
        // El estado de la atraccion pasa a FALSE => no esta en uso
        MappingAtracciones[_nombreAtraccion].estado_atraccion = false;
        // Emision del evento para la baja de la atraccion
        emit baja_atraccion(_nombreAtraccion);
    }

    // Visualizar las atracciones de Disney
    function AtraccionesDisponibles() public view returns (string [] memory) {
        return Atracciones;
    }

    // Funcion para subirse a una atraccion de Disney y pagar en tokens
    function SubirseAtraccion (string memory _nombreAtraccion) public {
        // Precio de la atraccion en tokens
        uint tokens_atraccion = MappingAtracciones[_nombreAtraccion].precio_atraccion;
        // Verifica el estado de la atraccion, disponible o no
        require (MappingAtracciones[_nombreAtraccion].estado_atraccion == true, "La atracción no está disponible en estos momentos.");
        // Verifica el numero de tokens que tiene el cliente para subirse a la atraccion
        require(tokens_atraccion <= MisTokens(), "Necesitas más Tokens para subirte a esta atracción.");

        /* El cliente paga la atraccion en Tokens:
        - Ha sido necesario crear una funcion en ERC20.sol con el
        nombre de 'transferencia_disney' debido a que en caso de usar
        el Transfer o TransferFrom las direcciones que se elegian
        eran equivocadas para realizar la transaccion. Ya que el msg.sender
        que recibia el metodo TransferFrom era la direccion del contrato
        */

        token.transferencia_disney(msg.sender, address(this), tokens_atraccion);
        
        // Almacenamiento en el historial de atracciones del cliente
        HistorialAtracciones[msg.sender].push(_nombreAtraccion);
        // Emision del evento para disfrutar de la atraccion
        emit disfuta_atraccion(_nombreAtraccion, tokens_atraccion, msg.sender);
    }

    //Visualiza el historial completo de atracciones disfrutadas por un cliente
    function Historial() public view returns (string [] memory) {
        return HistorialAtracciones[msg.sender];
    }

    // Funcion para que un cliente de Disney pueda devolver Tokens 
    function DevolverTokens (uint _numTokens) public payable {
        // El numero de tokens a devolver es positivo
        require (_numTokens > 0, "Necesitas devolver una cantidad positiva de tokens.");
        // El usuario debe tener el numero de tokens que desea devolver
        require (_numTokens <= MisTokens(), "No tienes los tokens que deseas devolver.");
        // El cleinte devuelve los tokens
        token.transferencia_disney(msg.sender, address(this), _numTokens);
        // Devolucion de los ethers al cliente
        msg.sender.transfer(PrecioTokens(_numTokens));
    }









}