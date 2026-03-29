use northwind;
-- ¿Cuáles son los 10 productos que más ingresos han generado?
SELECT
  p.ProductID,
  p.ProductName,
  SUM(od.Quantity * od.UnitPrice) AS TotalIngresos
FROM orderdetails od
JOIN products p       ON p.ProductID = od.ProductID
GROUP BY p.ProductID, p.ProductName
ORDER BY TotalIngresos DESC
LIMIT 10;

-- ¿Qué categorías de productos son más rentables?
SELECT
  c.CategoryID,
  c.CategoryName,
  SUM(od.Quantity * od.UnitPrice) AS TotalIngresos
FROM orderdetails od
JOIN products p     ON p.ProductID = od.ProductID
JOIN categories c   ON c.CategoryID = p.CategoryID
GROUP BY c.CategoryID, c.CategoryName
ORDER BY TotalIngresos DESC;

-- ¿Qué cliente ha realizado más compras en valor total?
SELECT
  cu.CustomerID,
  cu.CompanyName,
  SUM(od.Quantity * od.UnitPrice) AS TotalCompras
FROM orders o
JOIN customers cu     ON cu.CustomerID = o.CustomerID
JOIN orderdetails od  ON od.OrderID = o.OrderID
GROUP BY cu.CustomerID, cu.CompanyName
ORDER BY TotalCompras DESC
LIMIT 1;

-- ¿Qué país ha generado más ingresos en los últimos 12 meses?
SELECT
  cu.Country,
  SUM(od.Quantity * od.UnitPrice) AS TotalIngresos
FROM orders o
JOIN customers cu     ON cu.CustomerID = o.CustomerID
JOIN orderdetails od  ON od.OrderID = o.OrderID
WHERE o.OrderDate >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY cu.Country
ORDER BY TotalIngresos DESC
LIMIT 1;
-- ¿Qué empleado ha gestionado la mayor cantidad de pedidos?
select e.employeeid ID, concat(e.firstname,' ',e.lastname) Empleado, count(o.orderid) as NumPedidos -- Se llama la informacion de los empleados
-- Se realiza conteo de las ordenes para luego agruparla por empleado
from employees e
left join orders o on e.employeeid = o.employeeid -- se realiza un join de la tabla ordenes para tener los pedidos por empleados
group by e.employeeid, concat(e.firstname,' ',e.lastname) -- se agrupa por id y nombre completo evitando que se omitan datos
order by NumPedidos desc -- se realiza de manera desc para obtener los 3 mejores
limit 3; -- se pide el top 3, obteniendo los empleados que mas han gestionado pedidos 

-- ##### Analisis: teniendo en cuenta todos los datos, los empleados Angela Williams y Jeremiah Mathews son los que mas han gestionado pedidos con 274 c/u
-- El que sigue es Mark Miller con 270 pedidos, y la que menos pedidos ha gestionado es Amanda Calderon con 222. De 20 empleados, la diferencia es +50 pedidos
-- Por lo que que se tiene un buen equipo de ventas.

-- ¿Qué porcentaje de clientes no ha comprado nada?
with clientes_sin_comprar as ( -- creo un tabla temporal para obtener todos los clientes sin comprar
-- esto porque se pide porcentaje
select c.customerid 
From customers c
Left join orders o on c.customerid = o.customerid
where o.customerid is null -- se hace null 
)
select Count(cs.customerid) * 100.0 / count(c.customerid) porcentaje -- ya con los clientes sin comprar, se le realizan la operacion para tener el porcentaje
from customers c
left join clientes_sin_comprar cs on c.customerid = cs.customerid; -- se hace join con customer para realizar la operacion de porcentaje
-- #### Analisis: El porcentaje es de 0, todos los clientes registrados han comprado

-- ¿Cuáles son los 5 países con más clientes activos (que han realizado pedidos)?
select c.country Pais, count(distinct o.customerid) Clientes -- se realiza un distinct ya que pide clientes mas activos, por lo que se evita repeticiones de clientes
-- y asi obtener cantidad de clientes diferentes
from customers c -- se hace join la tabla de customers para obtener el pais de los clientes
left join orders o on c.customerid = o.customerid -- la tabla orders para tener los clientes activos que han comprado
group by c.country
order by clientes desc; -- para ver cual es el pais con clientes mas activos
-- #### Analisis: El pais que tiene mas clientes activos es IRAN, por lo que podriamos realizar ofertas en este pais, campanas o regalos, para si motivar
-- a clientes de otros pais a realizar mas compras

-- ¿Qué clientes han comprado más de 10 productos distintos?

select o.customerid, count(distinct od.productid) Productos -- se muestra l cantidad de productos que ha comprado cada cliente
from orders o -- orders para obtener los clientes y la cantidad de productos distintos que ha comprado c/u
left join orderdetails od on o.orderid = od.orderid -- se hace join con orderdetails para obtener los productoid
group by o.customerid -- se agrupa por clienteid
having count(distinct od.productid) > 10 -- se obtiene los clientes que cumplan la consigna 
order by productos desc; -- se ordena de mayor a menor
-- #### Analisis: solo dos clientes no han comprado mas de 10 productos, por lo que se tiene que analizar mas fondo esos dos clientes
-- Tambien se puede poner un limite mas alto que 10, para realizar un mejor analisis de los compras de los clientes
-- Las ventas son muy altas como para poner un limite de 10

-- ¿Hay clientes que compran solo un tipo de producto (una categoría)? -- 
with categoria_cliente as(
select c.CustomerID, c.CompanyName, count(distinct cat.CategoryName) num_categorias, count(distinct o.orderID)
from customers c
left join orders o on o.customerID=c.CustomerID
left join orderdetails odt on odt.OrderID=o.OrderID
left join products p on p.ProductID=odt.ProductID
left join categories cat on p.CategoryID=cat.CategoryID
group by c.CustomerID, c.CompanyName
order by num_categorias
)
select CustomerID, CompanyName, num_categorias
from categoria_cliente 
where num_categorias=1;



-- todos los clientes han comprado al menos más de una categoría.

-- ¿Cuál es el ticket promedio por pedido y cómo varía entre países? --
select Country, avg(total_pedido) prom_pedido
from (
select c.Country, o.orderID, sum(odt.Quantity*odt.UnitPrice) total_pedido
from customers c
join orders o on o.customerID=c.CustomerID
join orderdetails odt on odt.OrderID=o.OrderID
group by c.Country, o.orderID
) pedidos
group by Country
order by prom_pedido desc;

select avg(total_pedido) prom_pedido
from (
select c.Country, o.orderID, sum(odt.Quantity*odt.UnitPrice) total_pedido
from customers c
join orders o on o.customerID=c.CustomerID
join orderdetails odt on odt.OrderID=o.OrderID
group by c.Country, o.orderID
) pedidos;
-- Se calcula el promedio general del total de pedidos por país para poder medir una variación, en este caso el promedio por pedido es aproximadamente de $1264

select STDDEV(prom_pedido) as variacion_entre_paises
from (
select Country, avg(total_pedido) prom_pedido
from (
select c.Country, o.orderID, sum(odt.Quantity*odt.UnitPrice) total_pedido
from customers c
join orders o on o.customerID=c.CustomerID
join orderdetails odt on odt.OrderID=o.OrderID
group by c.Country, o.orderID
) pedidos
group by Country
order by prom_pedido desc
) prom_por_paises;
-- en esta consulta se determina la variación estandar con respecto al valor promedio por pedido de cada país, la desviación es de 221.67
-- Eso significa que, en promedio, los países se desvían alrededor de un 17–18% del ticket promedio global.
-- La mayoría de los países tiene tickets promedio relativamente cercanos a 1264
-- No hay países que se alejen de forma radical del comportamiento general
-- No hay evidencia de mercados “totalmente distintos”
-- El país no parece ser el factor dominante del gasto
-- No hay dispersión extrema entre países

-- ¿Cuál es el ranking de clientes por gasto total? --
select c.CustomerID, c.CompanyName, sum(odt.Quantity*odt.UnitPrice) gasto_total, concat(round(sum(odt.Quantity*odt.UnitPrice)*100/sum(sum(odt.Quantity*odt.UnitPrice))over(),2),'%') as peso_total
from customers c
join orders o on o.customerID=c.CustomerID
join orderdetails odt on odt.OrderID=o.OrderID
group by c.CustomerID, c.CompanyName
order by gasto_total DESC;
-- El análisis muestra que aproximadamente el 80% de las ventas proviene de cerca del 67% de los clientes, lo que indica una distribución relativamente equilibrada del ingreso y una baja dependencia de clientes individuales. No obstante, existe un grupo de clientes con baja contribución que representa una oportunidad de crecimiento.
-- Las ventas no están altamente concentradas en pocos clientes, lo que reduce el riesgo comercial y sugiere una cartera de clientes diversificada.

-- ¿Cuál es el total de productos vendidos por mes? --

with ventas_mensuales as (
select YEAR(o.OrderDate) as año, month(o.OrderDate) as mes, sum(odt.Quantity) total_productos
from customers c
left join orders o on o.customerID=c.CustomerID
left join orderdetails odt on odt.OrderID=o.OrderID
group by año, mes
)
SELECT
	año,

    SUM(CASE WHEN mes = 1  THEN total_productos ELSE 0 END) AS Enero,
    SUM(CASE WHEN mes = 2  THEN total_productos ELSE 0 END) AS Febrero,
    SUM(CASE WHEN mes = 3  THEN total_productos ELSE 0 END) AS Marzo,
    SUM(CASE WHEN mes = 4  THEN total_productos ELSE 0 END) AS Abril,
    SUM(CASE WHEN mes = 5  THEN total_productos ELSE 0 END) AS Mayo,
    SUM(CASE WHEN mes = 6  THEN total_productos ELSE 0 END) AS Junio,
    SUM(CASE WHEN mes = 7  THEN total_productos ELSE 0 END) AS Julio,
    SUM(CASE WHEN mes = 8  THEN total_productos ELSE 0 END) AS Agosto,
    SUM(CASE WHEN mes = 9  THEN total_productos ELSE 0 END) AS Septiembre,
    SUM(CASE WHEN mes = 10 THEN total_productos ELSE 0 END) AS Octubre,
    SUM(CASE WHEN mes = 11 THEN total_productos ELSE 0 END) AS Noviembre,
    SUM(CASE WHEN mes = 12 THEN total_productos ELSE 0 END) AS Diciembre,
    ROUND(AVG(total_productos), 2) AS prom_productos

FROM ventas_mensuales
group by año
order by año;
 
 -- Se puede observar que existe un ligero incremento del 0.3% con respecto al año 2022 al 2023 del total de productos vendidos por mes
 -- para el año 2024, solo tenemos la información completa de los meses de enero y febrero, y haciendo un promedio mensual de solo estos dos meses 
 -- se podría asumir que si se sigue la tendencia del promedio, el año 2024 incrementaría en un 5% el total de productos vendidos, sin embargo, es muy prematuro concluir con eso, pero sí fue un buen inicio de año.

-- ¿Cuál fue el mejor mes del en ventas del ultimo año?
select month(o.orderdate) mes, year(o.orderdate) año, sum(od.quantity*od.unitprice) ventas -- ventas=cantidad*precio unitario
from orders o left join orderdetails od on od.orderid=o.orderid 
group by año, mes 
order by año desc -- Ordenamos por año de mayor a menor para obtener el ultimo año y limitamos a 1 para obtener el mes con mejores ventas
limit 1;

-- ### ANALISIS: El análisis del último año disponible (2024) muestra que el mes con mayores ventas corresponde a enero, debido a que solo hay datos hasta marzo de ese año. 
-- Es importante destacar que este resultado no representa un año completo y, por tanto, no es comparable con periodos anteriores. 
-- Considerando toda la base de datos (2022–2024), el mayor volumen de ventas se registró en diciembre de 2023, reflejando la estacionalidad en el comportamiento de las ventas.

-- ¿Cuál es la evolucion del gasto acumulado por cliente?
select c.customerid, c.companyname, date_format(o.orderdate, '%Y-%m') periodo, sum(od.quantity*od.unitprice) gasto_mes, -- Se calcula el gasto mensual por cliente
sum(sum(od.quantity*od.unitprice)) over (partition by c.customerid order by date_format(o.orderdate, '%Y-%m')) gasto_acumulado
-- Sum interna agrupa los datos del mes y el externo acumula esos resultados mes a mes
-- Se reinicia la cuenta  para cada cliente distinto y se Va sumando en orden cronológico
from customers c	
inner join orders o on o.customerid = c.customerid
inner join orderdetails od on od.orderid=o.orderid
group by c.customerid, periodo;

-- ### ANALISIS: La evolución del gasto acumulado permite identificar a los clientes que generan mayor valor para la empresa en el tiempo. 
-- Se observa que algunos clientes concentran un crecimiento constante, indicando relaciones comerciales estables. 
-- Otros clientes presentan compras puntuales con menor impacto acumulado. Esta información es clave para priorizar estrategias de fidelización y retención.

-- ¿Qué productos se repiten como mas vendidos cada trimestre?

with ventas_trimestre as ( -- Se obtienen cuántas unidades se vendieron de cada producto por trimestre mediante un CTE
select year(o.orderdate) año, quarter(o.orderdate) trimestre, p.productname producto, sum(od.quantity) unidades_vendidas
from orders o
inner join orderdetails od on o.orderid = od.orderid
inner join products p on p.productid = od.productid
group by año, trimestre, p.productid
), ranking_trimestre as ( -- Creamos un ranking dentro de cada trimestre mediante otra CTE
select *, rank() over (partition by año, trimestre order by unidades_vendidas desc) rk
from ventas_trimestre
)
select año, trimestre, producto, unidades_vendidas -- Filtramos para mostrar solo a los ganadores (rk= 1)
from ranking_trimestre
where rk = 1
order by año, trimestre;

-- ### ANALISIS: El análisis trimestral evidencia que el producto líder cambia en cada periodo, sin repetición sostenida. 
-- Se observa variabilidad en las preferencias de compra a lo largo de los años analizados. 
-- El mayor volumen de ventas se registra en el cuarto trimestre de 2023. En 2024, el análisis se limita al primer trimestre debido a la disponibilidad de datos.

