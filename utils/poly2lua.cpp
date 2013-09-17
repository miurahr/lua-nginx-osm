#include <CGAL/Exact_predicates_inexact_constructions_kernel.h>
#include <CGAL/Partition_traits_2.h>
#include <CGAL/Partition_is_valid_traits_2.h>
#include <CGAL/polygon_function_objects.h>
#include <CGAL/partition_2.h>
#include <CGAL/point_generators_2.h>
#include <CGAL/random_polygon_2.h>
#include <CGAL/Polygon_2.h>
#include <list>
#include <iostream>
#include <fstream>
#include <iomanip>

typedef CGAL::Exact_predicates_inexact_constructions_kernel K;
typedef CGAL::Partition_traits_2<K>                         Traits;
typedef CGAL::Is_convex_2<Traits>                           Is_convex_2;
typedef Traits::Polygon_2                                   Polygon_2;
typedef Traits::Point_2                                     Point_2;
typedef Polygon_2::Vertex_const_iterator                    Vertex_iterator;
typedef std::list<Polygon_2>                                Polygon_list;
typedef CGAL::Partition_is_valid_traits_2<Traits, Is_convex_2>
                                                            Validity_traits;
typedef CGAL::Creator_uniform_2<int, Point_2>               Creator;
typedef CGAL::Random_points_in_square_2<Point_2, Creator>   Point_generator;
using std::cout; using std::endl;

template<class Kernel, class Container>
void print_polygon (const CGAL::Polygon_2<Kernel, Container>& P)
{
  typename CGAL::Polygon_2<Kernel, Container>::Vertex_const_iterator vit,vit_b;

  std::cout << "{" << std::endl;
  for (vit = vit_b = P.vertices_begin(); vit != P.vertices_end(); ++vit)
    std::cout << " {" << std::setprecision(9)  << vit->x() << "," << vit->y() << "}," << std::endl;
  std::cout << " {" << std::setprecision(9) << vit_b->x() << "," << vit_b->y() << "}," << std::endl;
  std::cout << " }," << std::endl;
}

void make_japan_polygon(Polygon_2& polygon)
{
   polygon.push_back(Point_2(153.890100, 26.382110));
   polygon.push_back(Point_2(132.152900, 26.468090));
   polygon.push_back(Point_2(131.691500, 21.209920));
   polygon.push_back(Point_2(122.595400, 23.519660));
   polygon.push_back(Point_2(122.560700, 25.841460));
   polygon.push_back(Point_2(128.814500, 34.748350));
   polygon.push_back(Point_2(129.396600, 35.094030));
   polygon.push_back(Point_2(135.307900, 37.547400));
   polygon.push_back(Point_2(140.576900, 45.706480));
   polygon.push_back(Point_2(149.189100, 45.802450));
}

int main(int argc, char *argv[])
{
    Polygon_2             polygon, poly;
    Polygon_list          partition_polys;
    Traits                partition_traits;
    Validity_traits       validity_traits;

    int testmode = 0;
    int debugmode = 0;
    int c;
    opterr = 0;
    while ((c = getopt (argc, argv, "td")) != -1)
    switch (c) {
        case 't':
            testmode = 1;
            break;
        case 'd':
            debugmode = 1;
            break;
        case '?':
            if (isprint (optopt))
                fprintf (stderr, "Unknown option `-%c'.\n", optopt);
            else
                fprintf (stderr,
                    "Unknown option character `\\x%x'.\n",
                    optopt);
             return 1;
        default:
            abort ();
    }

    if (testmode) {
        make_japan_polygon(polygon);
    } else {
        polygon.clear();
        std::cin >> polygon;
   }

   CGAL::approx_convex_partition_2(polygon.vertices_begin(),
                                    polygon.vertices_end(),
                                    std::back_inserter(partition_polys),
                                    partition_traits);

  std::cout << "local region = {" << std::endl;
  for (std::list<Polygon_2>::iterator pit = partition_polys.begin();
                                      pit != partition_polys.end();
                                    ++pit){
      print_polygon(*pit);
      if (debugmode) {
            // check if the polygon is convex
            std::cerr << "The polygon is " <<
                ((*pit).is_convex() ? "" : "not ") << "convex." << std::endl;
      }
   }
   std::cout << "}" << std::endl << "return region" << std::endl;
   return 0;
}

