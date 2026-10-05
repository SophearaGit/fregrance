# Fragrance backend (PHP + MySQL)

This folder replaces the old Node.js + MongoDB API. It runs on Laragon with nothing extra to install.

- `api/` is the API the Flutter app talks to. Same addresses and JSON as the old API.
- `admin/` is the admin website: products, brands, orders and users.
- `database/` holds `schema.sql` (the tables) and `seed.sql` (the 38 starting products and the sample customer).
- `uploads/` holds product images uploaded from the admin site.
- `app/` is the PHP code shared by the API and the admin site.
- `config.php` is written by the installer: MySQL connection and the secret that signs app logins. Keep it private.

## First-time setup

1. Start Laragon and click **Start All** (Apache and MySQL).
2. Open <http://localhost/fregrance_all/fragrance_backend/install.php>.
3. Leave the MySQL defaults (user `root`, empty password), choose an admin email and password, and press **Set up the database**.
4. Open the admin site: <http://localhost/fregrance_all/fragrance_backend/admin/>.

The database is called `fragrance_db`. You can browse it in HeidiSQL (Laragon's **Database** button).

To start over, delete `config.php`, open `install.php` again and tick **Replace existing tables**.

## The Flutter app

The app's API address is set in `fragrance_app/lib/core/network/api_config.dart`:

    http://localhost/fregrance_all/fragrance_backend/api

- Chrome or Windows desktop on this PC: `localhost` works as it is.
- Android emulator: use `http://10.0.2.2/fregrance_all/fragrance_backend/api`.
- A real phone on the same Wi-Fi: use this PC's IP address instead of `localhost`.
- If Laragon's Apache is not on port 80, add the port, for example `http://localhost:8080/...`.

To sign in to the app, create a customer under **Users** in the admin site (role "Customer") and give them a wallet balance.
Admin accounts are for the admin site.

## API quick reference

Base: `/fregrance_all/fragrance_backend/api`

| Method | Address | What it does |
| --- | --- | --- |
| GET | `/health` | Checks the API is running |
| POST | `/auth/register`, `/auth/login` | Returns `{ message, token }` |
| GET | `/user` | Signed-in user's profile |
| GET | `/product?search=&minRating=&maxRating=&page=&limit=` | All products |
| GET | `/product/featured` | New arrival, top sale, trending |
| GET | `/product/feed?tab=all\|new\|popular\|sale\|men\|women\|unisex` | Home feed |
| GET | `/product/brand`, `/product/brand/products?name=` | Brands and a brand's products |
| GET | `/product/discovery/moods`, `/notes`, `/occasions`, `/scent-families` | Discovery lists |
| GET | `/product/discovery/filter?mood=&note=&occasion=&family=&type=` | Discovery results |
| GET | `/product/detail/{id}` | One product |
| POST | `/product/batch` (also `/product/cart`) | Products for a list of ids |
| GET | `/wallet`, `/address` · POST `/address/add` | Customer wallet and addresses |
| POST | `/order` · GET `/order/processing`, `/order/history` · POST `/order/{id}/received` | Orders |

Endpoints that need a login expect the header `Authorization: Bearer <token>`.

## What is different from the old API

- Ids are numbers from MySQL, sent as text (`"12"`), instead of MongoDB ids.
- Products marked **hidden** in the admin site (status `inactive`) are left out of every list and cannot be ordered.
- An order charges each item at its price after discount, adds to the product's sold count, and marks it out of stock when the stock reaches 0.
- Registering creates an empty wallet for the new customer.
- `/product/discovery/scent-families` and the `family` filter return results (they came back empty before).

## If something does not work

- **install.php says it cannot connect:** MySQL is not running. Click Start All in Laragon.
- **The API address gives "Not Found" from Apache:** Laragon must be using Apache (not Nginx) with `mod_rewrite` on, which is its default.
- **The app shows no products:** open <http://localhost/fregrance_all/fragrance_backend/api/product/featured> in the browser. If that shows data, check the address in `api_config.dart` and restart the app.
