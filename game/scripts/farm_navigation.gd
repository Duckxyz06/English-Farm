extends RefCounted

const SCALE := 2.0
const WORLD_SIZE := Vector2(3072, 2048)
const CELL := 20.0
var regions: Array[PackedVector2Array] = []
var blocked: Array[Rect2] = []
var grid := AStarGrid2D.new()
var paths := AStar2D.new()

func _init() -> void:
    # Coordinates were traced against farm_spring.png (1536 x 1024).
    _polygon([[545,325],[650,298],[705,300],[740,252],[797,252],[820,300],[900,311],[978,352],[1000,384],[982,439],[961,494],[980,548],[1044,582],[1101,608],[1087,645],[994,627],[914,601],[843,592],[807,617],[726,617],[688,594],[610,608],[560,619],[511,623],[530,570],[547,497],[553,431],[513,390]])
    _rectangle(Rect2(376,234,48,148))
    _polygon([[278,346],[512,337],[582,345],[570,390],[450,407],[315,414],[291,386]])
    _rectangle(Rect2(746,65,45,230))
    _polygon([[951,352],[1111,322],[1170,290],[1215,291],[1213,331],[1324,337],[1395,332],[1410,382],[1301,397],[1170,388],[1043,430],[988,434]])
    _polygon([[525,507],[556,525],[555,578],[506,640],[453,682],[447,746],[460,803],[505,858],[553,901],[583,932],[555,957],[504,936],[445,876],[405,818],[392,745],[386,688],[403,623],[437,572],[455,516]])
    _polygon([[214,871],[282,874],[299,906],[365,904],[420,865],[458,883],[398,929],[323,949],[212,950],[197,915]])
    _polygon([[543,912],[599,884],[655,891],[703,920],[793,939],[863,927],[907,904],[996,886],[1050,900],[1042,933],[936,945],[851,973],[774,989],[675,966],[603,954],[554,959]])
    _rectangle(Rect2(613,667,353,177))
    _polygon([[729,827],[800,827],[821,894],[819,943],[749,940],[724,893]])
    _polygon([[979,561],[1069,590],[1171,605],[1251,608],[1308,611],[1330,639],[1307,668],[1245,665],[1223,643],[1140,642],[1059,634],[1004,608]])
    _rectangle(Rect2(1255,651,49,58))
    for rect in [Rect2(664,317,191,167),Rect2(607,448,61,48),Rect2(861,448,58,49),Rect2(678,484,46,51),Rect2(807,483,45,49)]:
        blocked.append(Rect2(rect.position * SCALE, rect.size * SCALE).grow(10))
    grid.region = Rect2i(0,0,ceili(WORLD_SIZE.x/CELL),ceili(WORLD_SIZE.y/CELL))
    grid.cell_size = Vector2.ONE * CELL
    grid.offset = Vector2.ONE * CELL * 0.5
    grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
    grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
    grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
    grid.update()
    for y in range(grid.region.size.y):
        for x in range(grid.region.size.x):
            var cell := Vector2i(x,y)
            grid.set_point_solid(cell, not is_walkable(grid.get_point_position(cell),12.0))
            if not grid.is_point_solid(cell):
                paths.add_point(_id(cell),grid.get_point_position(cell))
    # A grid can connect two safe centers across a concave path edge. Validate
    # each entire connection using the same footprint as actual movement.
    for y in range(grid.region.size.y):
        for x in range(grid.region.size.x):
            var cell := Vector2i(x,y)
            if grid.is_point_solid(cell):
                continue
            for offset in [Vector2i(1,0),Vector2i(0,1),Vector2i(1,1),Vector2i(-1,1)]:
                var neighbor: Vector2i = cell+offset
                if grid.region.has_point(neighbor) and not grid.is_point_solid(neighbor):
                    if can_travel(grid.get_point_position(cell),grid.get_point_position(neighbor),12.0):
                        paths.connect_points(_id(cell),_id(neighbor))

func _id(cell: Vector2i) -> int:
    return cell.y*grid.region.size.x+cell.x

func _polygon(points: Array) -> void:
    var polygon := PackedVector2Array()
    for point in points:
        polygon.append(Vector2(point[0], point[1]) * SCALE)
    regions.append(polygon)

func _rectangle(rect: Rect2) -> void:
    _polygon([[rect.position.x,rect.position.y],[rect.end.x,rect.position.y],[rect.end.x,rect.end.y],[rect.position.x,rect.end.y]])

func _inside(point: Vector2) -> bool:
    for area in blocked:
        if area.has_point(point):
            return false
    for polygon in regions:
        if Geometry2D.is_point_in_polygon(point, polygon):
            return true
    return false

func is_walkable(point: Vector2, clearance: float = 8.0) -> bool:
    for offset in [Vector2.ZERO,Vector2(clearance,0),Vector2(-clearance,0),Vector2(0,clearance),Vector2(0,-clearance)]:
        if not _inside(point + offset):
            return false
    return true

func can_travel(from: Vector2, to: Vector2, clearance: float = 8.0) -> bool:
    var steps := maxi(1,ceili(from.distance_to(to)/1.5))
    for i in range(steps+1):
        if not is_walkable(from.lerp(to,float(i)/steps),clearance):
            return false
    return true

func _nearest(point: Vector2, connect: bool) -> Vector2i:
    var best := Vector2i(-1,-1)
    var distance := INF
    for y in range(grid.region.size.y):
        for x in range(grid.region.size.x):
            var cell := Vector2i(x,y)
            if grid.is_point_solid(cell):
                continue
            var center := grid.get_point_position(cell)
            var d := center.distance_squared_to(point)
            if d < distance and (not connect or can_travel(point,center)):
                best = cell
                distance = d
    return best

func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
    var start := _nearest(from,true)
    var end := _nearest(to,false)
    if start.x < 0 or end.x < 0:
        return PackedVector2Array()
    var route := paths.get_point_path(_id(start),_id(end))
    if not route.is_empty() and can_travel(route[route.size()-1],to):
        route.append(to)
    return route
