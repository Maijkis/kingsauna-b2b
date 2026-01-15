/**
 * Kingsauna Analytics Tracker
 * Updated for new clean database structure
 * Links all data via visitor_id
 */

class KingsaunaAnalytics {
    constructor(supabaseClient) {
        this.supabase = supabaseClient;
        this.sessionId = this.getOrCreateSessionId();
        this.visitorId = this.getOrCreateVisitorId();
        this.pageLoadTime = Date.now();
        this.scrollDepth = 0;
        this.maxScrollDepth = 0;
        
        this.init();
    }
    
    // ==========================================
    // INITIALIZATION
    // ==========================================
    
    async init() {
        // First, ensure visitor exists in database
        await this.ensureVisitor();
        
        // Track page view
        await this.trackPageView();
        
        // Set up event listeners
        this.setupScrollTracking();
        this.setupCTATracking();
        this.setupLinkTracking();
        this.setupBeforeUnload();
        
        console.log('📊 Kingsauna Analytics initialized', {
            sessionId: this.sessionId,
            visitorId: this.visitorId
        });
    }
    
    // ==========================================
    // SESSION & VISITOR MANAGEMENT
    // ==========================================
    
    getOrCreateSessionId() {
        let sessionId = sessionStorage.getItem('ks_session_id');
        if (!sessionId) {
            sessionId = 'sess_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
            sessionStorage.setItem('ks_session_id', sessionId);
        }
        return sessionId;
    }
    
    getOrCreateVisitorId() {
        let visitorId = localStorage.getItem('ks_visitor_id');
        if (!visitorId) {
            visitorId = 'visitor_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
            localStorage.setItem('ks_visitor_id', visitorId);
        }
        return visitorId;
    }
    
    // ==========================================
    // VISITOR RECORD MANAGEMENT
    // ==========================================
    
    async ensureVisitor() {
        const urlParams = new URLSearchParams(window.location.search);
        
        const visitorData = {
            visitor_id: this.visitorId,
            session_id: this.sessionId,
            referrer: document.referrer || null,
            utm_source: urlParams.get('utm_source') || null,
            utm_medium: urlParams.get('utm_medium') || null,
            utm_campaign: urlParams.get('utm_campaign') || null,
            utm_content: urlParams.get('utm_content') || null,
            landing_page: window.location.pathname === '/' ? window.location.href : (localStorage.getItem('ks_landing_page') || window.location.href),
            device_type: this.getDeviceType(),
            browser: this.getBrowser()
        };
        
        // Store landing page if this is first visit
        if (!localStorage.getItem('ks_landing_page')) {
            localStorage.setItem('ks_landing_page', window.location.href);
            visitorData.landing_page = window.location.href;
        }
        
        try {
            // Try to insert (will fail if exists, that's okay)
            const { error: insertError } = await this.supabase
                .from('visitors')
                .insert([visitorData]);
            
            if (insertError && !insertError.message.includes('duplicate')) {
                console.warn('⚠️ Visitor insert issue:', insertError.message);
            }
            
            // Always update last_seen_at and increment session/page views
            const { error: updateError } = await this.supabase
                .from('visitors')
                .update({
                    last_seen_at: new Date().toISOString(),
                    total_sessions: this.supabase.raw('total_sessions + 1')
                })
                .eq('visitor_id', this.visitorId);
            
            if (updateError && !updateError.message.includes('duplicate')) {
                // If update fails, try upsert
                const { error: upsertError } = await this.supabase
                    .from('visitors')
                    .upsert({
                        ...visitorData,
                        last_seen_at: new Date().toISOString(),
                        total_page_views: 1,
                        total_sessions: 1
                    }, {
                        onConflict: 'visitor_id'
                    });
                
                if (upsertError) {
                    console.error('❌ Visitor upsert error:', upsertError);
                }
            }
        } catch (err) {
            console.error('❌ Visitor tracking failed:', err);
        }
    }
    
    // ==========================================
    // PAGE VIEW TRACKING
    // ==========================================
    
    async trackPageView() {
        const pageData = {
            visitor_id: this.visitorId,
            session_id: this.sessionId,
            page_url: window.location.href,
            page_path: window.location.pathname,
            page_title: document.title,
            referrer: document.referrer || null
        };
        
        try {
            const { error } = await this.supabase
                .from('page_views')
                .insert([pageData]);
            
            if (error) {
                console.error('❌ Page view tracking error:', error);
            } else {
                console.log('✅ Page view tracked');
                
                // Update visitor's total page views
                await this.supabase.rpc('increment_page_views', { 
                    visitor_id_param: this.visitorId 
                }).catch(() => {
                    // RPC might not exist, that's okay - we'll update manually
                    this.supabase
                        .from('visitors')
                        .update({ total_page_views: this.supabase.raw('total_page_views + 1') })
                        .eq('visitor_id', this.visitorId)
                        .then(() => {});
                });
            }
        } catch (err) {
            console.error('❌ Page view tracking failed:', err);
        }
    }
    
    // ==========================================
    // EVENT TRACKING
    // ==========================================
    
    async trackEvent(eventType, eventData = {}) {
        const event = {
            visitor_id: this.visitorId,
            session_id: this.sessionId,
            event_type: eventType,
            event_category: eventData.category || 'general',
            event_label: eventData.label || null,
            page_url: window.location.href,
            page_path: window.location.pathname,
            element_id: eventData.elementId || null,
            element_text: eventData.elementText || null,
            metadata: eventData.metadata ? JSON.stringify(eventData.metadata) : null
        };
        
        try {
            const { error } = await this.supabase
                .from('events')
                .insert([event]);
            
            if (error) {
                console.error('❌ Event tracking error:', error);
            } else {
                console.log('✅ Event tracked:', eventType);
            }
        } catch (err) {
            console.error('❌ Event tracking failed:', err);
        }
    }
    
    // ==========================================
    // FUNNEL TRACKING (as events)
    // ==========================================
    
    async trackFunnelStep(stepName, stepNumber, funnelType = null, metadata = {}) {
        await this.trackEvent('funnel_step', {
            category: 'funnel',
            label: stepName,
            metadata: {
                step_number: stepNumber,
                funnel_type: funnelType,
                ...metadata
            }
        });
    }
    
    // ==========================================
    // SCROLL TRACKING
    // ==========================================
    
    setupScrollTracking() {
        let ticking = false;
        
        window.addEventListener('scroll', () => {
            if (!ticking) {
                window.requestAnimationFrame(() => {
                    this.updateScrollDepth();
                    ticking = false;
                });
                ticking = true;
            }
        });
    }
    
    updateScrollDepth() {
        const windowHeight = window.innerHeight;
        const documentHeight = document.documentElement.scrollHeight;
        const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
        
        const scrollPercentage = Math.round((scrollTop / (documentHeight - windowHeight)) * 100);
        
        if (scrollPercentage > this.maxScrollDepth) {
            this.maxScrollDepth = scrollPercentage;
        }
    }
    
    // ==========================================
    // CTA BUTTON TRACKING
    // ==========================================
    
    setupCTATracking() {
        document.querySelectorAll('[class*="cta-"], button[onclick*="survey"]').forEach(button => {
            button.addEventListener('click', (e) => {
                const buttonText = e.target.textContent.trim() || e.target.innerText.trim();
                const buttonId = e.target.id || e.target.closest('[id]')?.id || 'no-id';
                
                this.trackEvent('cta_click', {
                    category: 'conversion',
                    label: buttonId,
                    elementText: buttonText,
                    elementId: buttonId
                });
            });
        });
    }
    
    // ==========================================
    // LINK TRACKING
    // ==========================================
    
    setupLinkTracking() {
        document.querySelectorAll('a[href]').forEach(link => {
            link.addEventListener('click', (e) => {
                const linkText = e.target.textContent.trim();
                const linkHref = e.target.href;
                const isExternal = linkHref && !linkHref.includes(window.location.hostname);
                
                this.trackEvent('link_click', {
                    category: isExternal ? 'external' : 'internal',
                    label: linkHref,
                    elementText: linkText,
                    metadata: { href: linkHref, external: isExternal }
                });
            });
        });
    }
    
    // ==========================================
    // UPDATE PAGE VIEW ON EXIT
    // ==========================================
    
    setupBeforeUnload() {
        // Update on page unload
        window.addEventListener('beforeunload', () => {
            this.updatePageViewOnExit();
        });
        
        // Also update periodically (every 30 seconds)
        setInterval(() => {
            this.updatePageViewOnExit();
        }, 30000);
    }
    
    async updatePageViewOnExit() {
        const timeOnPage = Math.round((Date.now() - this.pageLoadTime) / 1000);
        
        try {
            // Update the most recent page view for this session
            const { data: pageViews } = await this.supabase
                .from('page_views')
                .select('id')
                .eq('visitor_id', this.visitorId)
                .eq('session_id', this.sessionId)
                .order('created_at', { ascending: false })
                .limit(1);
            
            if (pageViews && pageViews.length > 0) {
                await this.supabase
                    .from('page_views')
                    .update({
                        time_on_page_seconds: timeOnPage,
                        scroll_depth: this.maxScrollDepth
                    })
                    .eq('id', pageViews[0].id);
            }
        } catch (err) {
            // Silently fail - not critical
        }
    }
    
    // ==========================================
    // DEVICE DETECTION UTILITIES
    // ==========================================
    
    getDeviceType() {
        const ua = navigator.userAgent;
        if (/(tablet|ipad|playbook|silk)|(android(?!.*mobi))/i.test(ua)) {
            return 'tablet';
        }
        if (/Mobile|Android|iP(hone|od)|IEMobile|BlackBerry|Kindle|Silk-Accelerated|(hpw|web)OS|Opera M(obi|ini)/.test(ua)) {
            return 'mobile';
        }
        return 'desktop';
    }
    
    getBrowser() {
        const ua = navigator.userAgent;
        if (ua.includes('Firefox')) return 'Firefox';
        if (ua.includes('Edg')) return 'Edge';
        if (ua.includes('Chrome')) return 'Chrome';
        if (ua.includes('Safari')) return 'Safari';
        if (ua.includes('Opera')) return 'Opera';
        return 'Unknown';
    }
    
    getOS() {
        const ua = navigator.userAgent;
        if (ua.includes('Win')) return 'Windows';
        if (ua.includes('Mac')) return 'MacOS';
        if (ua.includes('Linux')) return 'Linux';
        if (ua.includes('Android')) return 'Android';
        if (ua.includes('iOS') || ua.includes('iPhone') || ua.includes('iPad')) return 'iOS';
        return 'Unknown';
    }
}

// ==========================================
// EXPORT FOR USE
// ==========================================

// Initialize analytics when Supabase is ready
window.initKingsaunaAnalytics = function(supabaseClient) {
    window.ksAnalytics = new KingsaunaAnalytics(supabaseClient);
    return window.ksAnalytics;
};
