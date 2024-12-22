import 'package:vania/vania.dart';
import 'package:vania_tugas/app/http/controllers/customer_controller.dart';
import 'package:vania_tugas/app/http/controllers/order_controller.dart';
import 'package:vania_tugas/app/http/controllers/vendors_controller.dart';
import 'package:vania_tugas/app/http/controllers/order_items_controller.dart';
import 'package:vania_tugas/app/http/controllers/product_notes_controller.dart';
import 'package:vania_tugas/app/http/controllers/products_controller.dart';
import 'package:vania_tugas/app/http/middleware/authenticate.dart';

class ApiRoute implements Route {
  @override
  void register() {
    Router.basePrefix('api');

    // Rute Customer
    Router.get("/customers", customerController.index);
    Router.post("/customers", customerController.store);
    Router.put("/customers", customerController.update);
    Router.delete("/customers", customerController.delete);
    Router.post("/customers/login", customerController.login);

    // Rute Orders dengan middleware autentikasi
    Router.group(() {
      Router.get("/orders", ordersController.index);
      Router.post("/orders", ordersController.store);
      Router.put("/orders", ordersController.update);
      Router.delete("/orders", ordersController.delete);
    }, middleware: [AuthMiddleware()]);

    // Rute Vendors dengan middleware validasi token
    Router.group(() {
      Router.get("/vendors", vendorsController.index);
      Router.post("/vendors", vendorsController.store);
      Router.put("/vendors", vendorsController.update);
      Router.delete("/vendors", vendorsController.delete);
    }, middleware: [AuthMiddleware()]);

    // Rute Products dengan middleware autentikasi
    Router.group(() {
      Router.get("/products", productsController.index);
      Router.post("/products", productsController.store);
      Router.put("/products", productsController.update);
      Router.delete("/products", productsController.delete);
    }, middleware: [AuthMiddleware()]);

    // Rute OrderItems dengan middleware autentikasi
    Router.group(() {
      Router.get("/order_items", orderItemsController.index);
      Router.post("/order_items", orderItemsController.store);
      Router.put("/order_items", orderItemsController.update);
      Router.delete("/order_items", orderItemsController.delete);
    }, middleware: [AuthMiddleware()]);

    // Rute ProductNotes dengan middleware autentikasi
    Router.group(() {
      Router.get("/product_notes", productNotesController.index);
      Router.post("/product_notes", productNotesController.store);
      Router.put("/product_notes", productNotesController.update);
      Router.delete("/product_notes", productNotesController.delete);
    }, middleware: [AuthMiddleware()]);
  }
}
