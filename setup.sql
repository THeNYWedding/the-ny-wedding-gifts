-- Configuration complète pour Supabase
-- Exécutez ce script dans l'éditeur SQL de votre projet Supabase

-- 1. Créer la table des cadeaux
CREATE TABLE IF NOT EXISTS gifts (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  price TEXT NOT NULL,
  category TEXT NOT NULL,
  category_icon TEXT DEFAULT '🎁',
  link TEXT,
  button_text TEXT DEFAULT 'Réserver ce cadeau',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Créer la table des réservations
CREATE TABLE IF NOT EXISTS reservations (
  gift_id INTEGER PRIMARY KEY REFERENCES gifts(id) ON DELETE CASCADE,
  guest_name TEXT NOT NULL,
  guest_email TEXT,
  reserved_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Activer Row Level Security (RLS)
ALTER TABLE gifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE reservations ENABLE ROW LEVEL SECURITY;

-- 4. Politiques de sécurité pour la table gifts
-- Permettre la lecture à tous
CREATE POLICY "Allow read access to gifts" ON gifts FOR SELECT USING (true);

-- Permettre l'insertion, la mise à jour et la suppression à tous (pour l'admin)
-- Note: En production, vous devriez restreindre cela aux administrateurs uniquement
CREATE POLICY "Allow full access to gifts" ON gifts FOR ALL USING (true);

-- 5. Politiques de sécurité pour la table reservations
-- Permettre la lecture à tous
CREATE POLICY "Allow read access to reservations" ON reservations FOR SELECT USING (true);

-- Permettre l'insertion à tous (pour que les invités puissent réserver)
CREATE POLICY "Allow insert access to reservations" ON reservations FOR INSERT WITH CHECK (true);

-- Permettre la suppression à tous (pour que l'admin puisse annuler)
CREATE POLICY "Allow delete access to reservations" ON reservations FOR DELETE USING (true);

-- 6. Insérer des données d'exemple
INSERT INTO gifts (name, description, price, category, category_icon, link, button_text) VALUES
('Set de casseroles inox', 'Set complet de casseroles haute qualité avec couvercles', '150€ - 200€', 'Pour la Maison', '🏠', 'https://www.amazon.fr/s?k=set+casseroles+inox', 'Réserver ce cadeau'),
('Machine à café', 'Cafetière automatique avec broyeur intégré', '200€ - 300€', 'Pour la Maison', '🏠', 'https://www.amazon.fr/s?k=machine+cafe+broyeur', 'Réserver ce cadeau'),
('Aspirateur robot', 'Robot aspirateur intelligent programmable', '250€ - 400€', 'Pour la Maison', '🏠', 'https://www.amazon.fr/s?k=aspirateur+robot', 'Réserver ce cadeau'),
('Parure de lit', 'Housse de couette + taies d''oreiller en coton bio', '80€ - 120€', 'Pour la Maison', '🏠', NULL, 'Réserver ce cadeau'),
('Service de vaisselle', 'Service complet pour 6 personnes en porcelaine', '120€ - 180€', 'Art de la Table', '🍽️', 'https://www.amazon.fr/s?k=service+vaisselle+porcelaine', 'Réserver ce cadeau'),
('Couverts en inox', 'Ménagère 24 pièces design moderne', '60€ - 100€', 'Art de la Table', '🍽️', 'https://www.amazon.fr/s?k=menagere+couverts+inox', 'Réserver ce cadeau'),
('Verres à vin', 'Set de 6 verres à vin en cristal', '40€ - 80€', 'Art de la Table', '🍽️', 'https://www.amazon.fr/s?k=verres+vin+cristal', 'Réserver ce cadeau'),
('Planche à découper', 'Grande planche en bois massif avec accessoires', '50€ - 80€', 'Art de la Table', '🍽️', NULL, 'Réserver ce cadeau'),
('Voyage de noces', 'Une contribution pour notre lune de miel', 'Montant libre', 'Contribution Libre', '💰', NULL, 'Contribuer'),
('Projet maison', 'Aide pour l''aménagement de notre nouveau foyer', 'Montant libre', 'Contribution Libre', '💰', NULL, 'Contribuer'),
('Mixeur plongeant', 'Mixeur plongeant professionnel avec accessoires', '40€ - 70€', 'Électroménager', '⚡', 'https://www.amazon.fr/s?k=mixeur+plongeant', 'Réserver ce cadeau'),
('Grille-pain', 'Grille-pain 2 fentes avec réglages multiples', '30€ - 60€', 'Électroménager', '⚡', 'https://www.amazon.fr/s?k=grille+pain', 'Réserver ce cadeau'),
('Bouilloire électrique', 'Bouilloire en inox avec température réglable', '50€ - 90€', 'Électroménager', '⚡', 'https://www.amazon.fr/s?k=bouilloire+electrique+inox', 'Réserver ce cadeau');

-- 7. Créer des index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_gifts_category ON gifts(category);
CREATE INDEX IF NOT EXISTS idx_reservations_gift_id ON reservations(gift_id);
CREATE INDEX IF NOT EXISTS idx_reservations_reserved_at ON reservations(reserved_at);

-- 8. Créer une vue pour faciliter les jointures (optionnel)
CREATE OR REPLACE VIEW gifts_with_reservations AS
SELECT 
  g.*,
  r.guest_name,
  r.guest_email,
  r.reserved_at,
  CASE WHEN r.gift_id IS NOT NULL THEN true ELSE false END as is_reserved
FROM gifts g
LEFT JOIN reservations r ON g.id = r.gift_id
ORDER BY g.id;

-- 9. Fonction pour obtenir les statistiques (optionnel)
CREATE OR REPLACE FUNCTION get_wedding_stats()
RETURNS TABLE(
  total_gifts INTEGER,
  reserved_gifts INTEGER,
  available_gifts INTEGER,
  unique_guests INTEGER
) 
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    (SELECT COUNT(*)::INTEGER FROM gifts) as total_gifts,
    (SELECT COUNT(*)::INTEGER FROM reservations) as reserved_gifts,
    (SELECT COUNT(*)::INTEGER FROM gifts WHERE id NOT IN (SELECT gift_id FROM reservations)) as available_gifts,
    (SELECT COUNT(DISTINCT guest_name)::INTEGER FROM reservations) as unique_guests;
END;
$$ LANGUAGE plpgsql;

-- Configuration terminée !
-- Vos tables sont prêtes et les données d'exemple sont insérées.
-- N'oubliez pas de récupérer votre URL et votre clé publique dans Settings > API
