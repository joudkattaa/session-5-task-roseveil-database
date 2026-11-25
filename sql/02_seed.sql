-- Run after 01_schema.sql, once. All names and customer records are fictional.
-- Prices are illustrative USD amounts. Seed orders are historical;
-- seeded stock is the current stock AFTER those historical purchases.
BEGIN;

INSERT INTO categories (name, description) VALUES
('Makeup', 'Color cosmetics for face, eyes, and lips'),
('Skincare', 'Daily cleansing, hydration, and skin care'),
('Perfume', 'Personal fragrances'),
('Beauty Tools', 'Reusable beauty accessories');

INSERT INTO products (category_id, sku, name, price, stock)
SELECT c.category_id, v.sku, v.name, v.price, v.stock
FROM (VALUES
('Makeup', 'RV-M01', 'Petal Satin Lipstick', 18.00, 60),
('Makeup', 'RV-M02', 'Rosewater Lip Gloss', 14.00, 45),
('Makeup', 'RV-M03', 'Velvet Cloud Foundation', 32.00, 35),
('Makeup', 'RV-M04', 'Soft Focus Concealer', 20.00, 40),
('Makeup', 'RV-M05', 'Bloom Cream Blush', 22.00, 50),
('Makeup', 'RV-M06', 'Moonlit Highlighter', 24.00, 28),
('Makeup', 'RV-M07', 'Dusk Eyeshadow Palette', 38.00, 25),
('Makeup', 'RV-M08', 'Lash Veil Mascara', 19.00, 55),
('Makeup', 'RV-M09', 'Fine Line Eyeliner', 15.00, 48),
('Makeup', 'RV-M10', 'Silk Setting Powder', 26.00, 30),
('Skincare', 'RV-S01', 'Gentle Petal Cleanser', 21.00, 65),
('Skincare', 'RV-S02', 'Dewdrop Hydrating Toner', 23.00, 42),
('Skincare', 'RV-S03', 'Hyaluronic Dew Serum', 34.00, 38),
('Skincare', 'RV-S04', 'Ceramide Comfort Cream', 29.00, 44),
('Skincare', 'RV-S05', 'Daily Veil SPF 50', 27.00, 70),
('Skincare', 'RV-S06', 'Overnight Recovery Mask', 31.00, 22),
('Skincare', 'RV-S07', 'Cooling Eye Gel', 25.00, 33),
('Skincare', 'RV-S08', 'Rose Lip Balm', 9.00, 80),
('Skincare', 'RV-S09', 'Soft Clay Mask', 24.00, 26),
('Skincare', 'RV-S10', 'Milky Cleansing Oil', 28.00, 36),
('Perfume', 'RV-P01', 'Roseveil Eau de Parfum 50ml', 78.00, 20),
('Perfume', 'RV-P02', 'Amber Garden Eau de Parfum 50ml', 85.00, 18),
('Perfume', 'RV-P03', 'Citrus Dawn Eau de Toilette 50ml', 62.00, 24),
('Perfume', 'RV-P04', 'White Petal Perfume Oil 10ml', 35.00, 32),
('Perfume', 'RV-P05', 'Evening Bloom Travel Spray 10ml', 22.00, 40),
('Perfume', 'RV-P06', 'Fragrance Discovery Set', 30.00, 15),
('Beauty Tools', 'RV-B01', 'Rose Gold Powder Brush', 16.00, 45),
('Beauty Tools', 'RV-B02', 'Velvet Blending Sponge', 8.00, 90),
('Beauty Tools', 'RV-B03', 'Precision Brow Tweezer', 10.00, 37),
('Beauty Tools', 'RV-B04', 'Satin Cosmetic Pouch', 18.00, 29),
('Beauty Tools', 'RV-B05', 'Silicone Cleansing Pad', 7.00, 52),
('Beauty Tools', 'RV-B06', 'Compact Travel Mirror', 12.00, 0)
) AS v(category_name, sku, name, price, stock)
JOIN categories c ON c.name = v.category_name;

INSERT INTO customers (full_name, email, city) VALUES
('Mira Vale', 'mira.vale@example.com', 'Istanbul'),
('Lina Rowan', 'lina.rowan@example.com', 'Ankara'),
('Nora Finch', 'nora.finch@example.com', 'Izmir'),
('Selin Ash', 'selin.ash@example.com', 'Bursa'),
('Ada Wren', 'ada.wren@example.com', 'Antalya'),
('Leila Moss', 'leila.moss@example.com', 'Istanbul'),
('Derya Bloom', 'derya.bloom@example.com', 'Eskisehir'),
('Elif Reed', 'elif.reed@example.com', 'Ankara');

-- Explicit historical prices deliberately differ from some current prices.
INSERT INTO orders (customer_id, product_id, quantity, unit_price, ordered_at)
SELECT c.customer_id, p.product_id, v.quantity, v.unit_price, v.ordered_at::TIMESTAMPTZ
FROM (VALUES
('mira.vale@example.com', 'RV-M01', 2, 17.00, '2026-10-01 10:00:00+03'),
('mira.vale@example.com', 'RV-S01', 1, 21.00, '2026-10-01 10:00:00+03'),
('lina.rowan@example.com', 'RV-P01', 1, 75.00, '2026-10-03 12:30:00+03'),
('nora.finch@example.com', 'RV-S03', 2, 34.00, '2026-10-05 09:00:00+03'),
('selin.ash@example.com', 'RV-B02', 3, 8.00, '2026-10-08 16:15:00+03'),
('ada.wren@example.com', 'RV-M07', 1, 38.00, '2026-10-10 14:00:00+03'),
('leila.moss@example.com', 'RV-S05', 2, 26.00, '2026-10-12 11:45:00+03'),
('mira.vale@example.com', 'RV-P05', 1, 22.00, '2026-10-15 18:00:00+03'),
('lina.rowan@example.com', 'RV-M08', 1, 19.00, '2026-10-17 10:30:00+03'),
('nora.finch@example.com', 'RV-B01', 2, 16.00, '2026-10-20 13:00:00+03'),
('selin.ash@example.com', 'RV-S04', 1, 29.00, '2026-10-22 15:00:00+03'),
('ada.wren@example.com', 'RV-P03', 1, 60.00, '2026-10-24 17:30:00+03')
) AS v(email, sku, quantity, unit_price, ordered_at)
JOIN customers c ON c.email = v.email
JOIN products p ON p.sku = v.sku;

COMMIT;

SELECT 'categories' AS table_name, COUNT(*) FROM categories
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'customers', COUNT(*) FROM customers
UNION ALL SELECT 'orders', COUNT(*) FROM orders;
